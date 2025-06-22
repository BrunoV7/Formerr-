# Backup and Disaster Recovery Configuration

## Production Database Backup (DigitalOcean Managed Database)

The production environment uses a managed DigitalOcean PostgreSQL database which provides:
- Automated daily backups (retained for 7 days by default)
- Point-in-time recovery
- High availability with standby replicas
- Automated patching and maintenance

### Manual Backup Commands

```bash
# Create a manual backup snapshot
doctl databases backup create <database-id>

# List available backups
doctl databases backup list <database-id>

# Restore from backup (creates new database cluster)
doctl databases create <new-cluster-name> --engine pg --version 14 --region nyc1 --size db-s-1vcpu-1gb --restore-from-backup <backup-id>
```

## Staging Database Backup (In-Cluster PostgreSQL)

For the staging environment, we use Velero for backup and disaster recovery:

### Velero Installation

```bash
# Install Velero CLI
curl -fsSL -o velero-v1.12.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.12.1/velero-v1.12.1-linux-amd64.tar.gz
tar -xzf velero-v1.12.1-linux-amd64.tar.gz
sudo mv velero-v1.12.1-linux-amd64/velero /usr/local/bin/

# Install Velero in cluster with DigitalOcean Spaces backend
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.1 \
    --bucket <your-spaces-bucket> \
    --secret-file ./credentials-velero \
    --backup-location-config region=<your-region>,s3ForcePathStyle="true",s3Url=https://<your-region>.digitaloceanspaces.com \
    --snapshot-location-config region=<your-region>
```

### Backup Schedule Configuration

```bash
# Create daily backup schedule
velero create schedule daily-backup --schedule="@daily" --ttl 168h0m0s

# Create weekly backup schedule  
velero create schedule weekly-backup --schedule="@weekly" --ttl 720h0m0s

# Backup specific namespace
velero backup create formerr-backup --include-namespaces formerr

# Restore from backup
velero restore create --from-backup formerr-backup
```

## Application Data Backup

### User-Generated Content Backup

If your application stores files, implement a backup strategy:

```yaml
# Example: Periodic job to backup user uploads to DigitalOcean Spaces
apiVersion: batch/v1
kind: CronJob
metadata:
  name: user-content-backup
  namespace: formerr
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: rclone/rclone:latest
            command:
            - /bin/sh
            - -c
            - |
              rclone sync /app/uploads s3:backup-bucket/user-uploads/$(date +%Y-%m-%d)
            volumeMounts:
            - name: uploads
              mountPath: /app/uploads
            env:
            - name: RCLONE_CONFIG_S3_TYPE
              value: "s3"
            - name: RCLONE_CONFIG_S3_PROVIDER
              value: "DigitalOcean"
            - name: RCLONE_CONFIG_S3_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: backup-credentials
                  key: access-key
            - name: RCLONE_CONFIG_S3_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: backup-credentials
                  key: secret-key
            - name: RCLONE_CONFIG_S3_ENDPOINT
              value: "https://nyc3.digitaloceanspaces.com"
          volumes:
          - name: uploads
            persistentVolumeClaim:
              claimName: user-uploads-pvc
          restartPolicy: OnFailure
```

## Disaster Recovery Procedures

### 1. Database Recovery (Production)

```bash
# In case of database failure:
# 1. Check DigitalOcean dashboard for database status
# 2. If corrupted, restore from latest backup:
doctl databases create formerr-prod-recovery --engine pg --version 14 --region nyc1 --size db-s-2vcpu-4gb --restore-from-backup <backup-id>

# 3. Update Kubernetes secrets with new database credentials:
kubectl create secret generic formerr-db-secret \
  --namespace=formerr \
  --from-literal=DATABASE_URL="postgresql://user:pass@new-host:5432/dbname" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Restart application pods:
kubectl rollout restart deployment/formerr-backend -n formerr
```

### 2. Cluster Recovery

```bash
# If entire cluster is lost:
# 1. Re-run Terraform to recreate infrastructure:
cd infrastructure/digitalocean-production
terraform apply -auto-approve

# 2. Re-run the GitHub Actions workflow to deploy applications

# 3. For staging, restore from Velero backup:
velero restore create cluster-restore --from-backup <backup-name>
```

### 3. Application Recovery

```bash
# Rolling back to previous version:
kubectl rollout undo deployment/formerr-backend -n formerr
kubectl rollout undo deployment/formerr-frontend -n formerr

# Or deploy specific version:
kubectl set image deployment/formerr-backend backend=registry.digitalocean.com/formerr-production/formerr-backend:<previous-tag> -n formerr
```

## Monitoring and Alerting for Backups

Add these alerts to your Prometheus configuration:

```yaml
- alert: BackupFailed
  expr: increase(velero_backup_failure_total[1h]) > 0
  for: 0m
  labels:
    severity: critical
  annotations:
    summary: "Backup failed"
    description: "Velero backup has failed in the last hour"

- alert: DatabaseBackupOld
  expr: time() - pg_backup_last_time > 86400 * 2  # 2 days
  for: 0m
  labels:
    severity: warning
  annotations:
    summary: "Database backup is old"
    description: "Database backup is older than 2 days"
```

## Testing Recovery Procedures

### Monthly DR Testing Checklist

1. **Database Recovery Test (Staging)**
   - [ ] Create test backup
   - [ ] Restore to new database instance
   - [ ] Verify data integrity
   - [ ] Test application connectivity

2. **Application Recovery Test**
   - [ ] Deploy to test namespace
   - [ ] Verify all services start correctly
   - [ ] Test critical user workflows
   - [ ] Verify monitoring and logging

3. **Infrastructure Recovery Test**
   - [ ] Create new cluster in different region
   - [ ] Deploy full stack
   - [ ] Test DNS failover (if configured)
   - [ ] Verify performance benchmarks

This backup and disaster recovery strategy ensures your Formerr application can recover from various failure scenarios while maintaining data integrity and minimizing downtime.
