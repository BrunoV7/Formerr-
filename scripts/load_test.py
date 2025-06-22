#!/usr/bin/env python3
"""
Load testing script for Formerr application using Locust.
This script tests various endpoints and user scenarios.
"""

import random
import json
from locust import HttpUser, task, between, events
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FormerrUser(HttpUser):
    """Simulates a user interacting with the Formerr application."""
    
    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    
    def on_start(self):
        """Called when a user starts. Performs login if needed."""
        self.client.verify = False  # Disable SSL verification for testing
        self.auth_token = None
        self.user_id = None
        
        # Try to authenticate
        self.login()
    
    def login(self):
        """Simulate user login process."""
        try:
            # Test login endpoint
            response = self.client.post("/api/v1/auth/login", json={
                "email": f"testuser{random.randint(1, 1000)}@example.com",
                "password": "testpassword123"
            })
            
            if response.status_code == 200:
                data = response.json()
                self.auth_token = data.get("access_token")
                self.user_id = data.get("user_id")
                logger.info(f"Login successful for user {self.user_id}")
            else:
                logger.warning(f"Login failed with status {response.status_code}")
                
        except Exception as e:
            logger.error(f"Login error: {e}")
    
    @property
    def headers(self):
        """Return headers with auth token if available."""
        headers = {"Content-Type": "application/json"}
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        return headers
    
    @task(3)
    def view_homepage(self):
        """Test loading the homepage."""
        self.client.get("/", name="homepage")
    
    @task(2)
    def view_dashboard(self):
        """Test loading the dashboard."""
        self.client.get("/dashboard", headers=self.headers, name="dashboard")
    
    @task(4)
    def list_forms(self):
        """Test listing forms endpoint."""
        self.client.get("/api/v1/forms", headers=self.headers, name="list_forms")
    
    @task(3)
    def create_form(self):
        """Test creating a new form."""
        form_data = {
            "title": f"Test Form {random.randint(1, 10000)}",
            "description": "This is a test form created during load testing",
            "fields": [
                {
                    "type": "text",
                    "label": "Name",
                    "required": True,
                    "placeholder": "Enter your name"
                },
                {
                    "type": "email", 
                    "label": "Email",
                    "required": True,
                    "placeholder": "Enter your email"
                },
                {
                    "type": "textarea",
                    "label": "Message",
                    "required": False,
                    "placeholder": "Enter your message"
                }
            ],
            "settings": {
                "allowAnonymous": True,
                "requireLogin": False,
                "maxSubmissions": 1000
            }
        }
        
        response = self.client.post(
            "/api/v1/forms",
            json=form_data,
            headers=self.headers,
            name="create_form"
        )
        
        if response.status_code == 201:
            form_id = response.json().get("id")
            # Store form ID for later use
            if not hasattr(self, 'created_forms'):
                self.created_forms = []
            self.created_forms.append(form_id)
    
    @task(2)
    def view_form(self):
        """Test viewing a specific form."""
        # Try to view a form we created, or use a default ID
        form_id = None
        if hasattr(self, 'created_forms') and self.created_forms:
            form_id = random.choice(self.created_forms)
        else:
            form_id = random.randint(1, 100)  # Random form ID
        
        self.client.get(
            f"/api/v1/forms/{form_id}",
            headers=self.headers,
            name="view_form"
        )
    
    @task(1)
    def submit_form(self):
        """Test submitting a form response."""
        # Use a form we created or a default one
        form_id = None
        if hasattr(self, 'created_forms') and self.created_forms:
            form_id = random.choice(self.created_forms)
        else:
            form_id = random.randint(1, 10)
        
        submission_data = {
            "responses": {
                "name": f"Test User {random.randint(1, 1000)}",
                "email": f"test{random.randint(1, 1000)}@example.com",
                "message": "This is a test submission from load testing"
            }
        }
        
        self.client.post(
            f"/api/v1/forms/{form_id}/submit",
            json=submission_data,
            headers=self.headers,
            name="submit_form"
        )
    
    @task(1)
    def view_form_submissions(self):
        """Test viewing form submissions."""
        if hasattr(self, 'created_forms') and self.created_forms:
            form_id = random.choice(self.created_forms)
            self.client.get(
                f"/api/v1/forms/{form_id}/submissions",
                headers=self.headers,
                name="view_submissions"
            )
    
    @task(1)
    def health_check(self):
        """Test health check endpoint."""
        self.client.get("/health", name="health_check")
    
    @task(1)
    def api_health_check(self):
        """Test API health check endpoint."""
        self.client.get("/api/health", name="api_health_check")


class AdminUser(HttpUser):
    """Simulates an admin user with additional privileges."""
    
    wait_time = between(2, 5)
    weight = 1  # Lower weight means fewer admin users
    
    def on_start(self):
        """Admin login process."""
        self.client.verify = False
        self.auth_token = None
        self.admin_login()
    
    def admin_login(self):
        """Simulate admin login."""
        try:
            response = self.client.post("/api/v1/auth/login", json={
                "email": "admin@example.com",
                "password": "adminpassword123"
            })
            
            if response.status_code == 200:
                data = response.json()
                self.auth_token = data.get("access_token")
                logger.info("Admin login successful")
                
        except Exception as e:
            logger.error(f"Admin login error: {e}")
    
    @property
    def headers(self):
        """Return admin headers."""
        headers = {"Content-Type": "application/json"}
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        return headers
    
    @task(2)
    def view_admin_dashboard(self):
        """Test admin dashboard."""
        self.client.get("/admin/dashboard", headers=self.headers, name="admin_dashboard")
    
    @task(1)
    def view_all_forms(self):
        """Test viewing all forms (admin privilege)."""
        self.client.get("/api/v1/admin/forms", headers=self.headers, name="admin_view_all_forms")
    
    @task(1)
    def view_analytics(self):
        """Test analytics endpoint."""
        self.client.get("/api/v1/admin/analytics", headers=self.headers, name="admin_analytics")
    
    @task(1)
    def view_user_management(self):
        """Test user management."""
        self.client.get("/api/v1/admin/users", headers=self.headers, name="admin_users")


# Event handlers for custom metrics
@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when the test starts."""
    logger.info("Starting Formerr load test...")
    print("🚀 Starting Formerr load test...")

@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when the test stops."""
    logger.info("Formerr load test completed.")
    print("✅ Formerr load test completed.")

@events.request_failure.add_listener
def on_request_failure(request_type, name, response_time, response_length, exception, **kwargs):
    """Log request failures."""
    logger.error(f"Request failed: {request_type} {name} - {exception}")

@events.request_success.add_listener  
def on_request_success(request_type, name, response_time, response_length, **kwargs):
    """Log successful requests (optional, can be noisy)."""
    if response_time > 2000:  # Log slow requests > 2 seconds
        logger.warning(f"Slow request: {request_type} {name} - {response_time}ms")


if __name__ == "__main__":
    """
    Run load test locally:
    
    # Install locust
    pip install locust
    
    # Run with web UI
    locust -f load_test.py --host=https://your-formerr-domain.com
    
    # Run headless
    locust -f load_test.py --host=https://your-formerr-domain.com --users 50 --spawn-rate 5 --run-time 300s --headless
    """
    import os
    import sys
    
    # Add some example usage
    print("Formerr Load Test Script")
    print("=" * 40)
    print("Usage examples:")
    print("1. Web UI:    locust -f load_test.py --host=https://formerr.example.com")
    print("2. Headless:  locust -f load_test.py --host=https://formerr.example.com --users 50 --spawn-rate 5 --run-time 300s --headless")
    print("3. With specific config: locust -f load_test.py --host=https://formerr.example.com --config=locust.conf")
    print("\nDefault user classes:")
    print("- FormerrUser: Regular application users (weight: 10)")
    print("- AdminUser: Admin users (weight: 1)")
