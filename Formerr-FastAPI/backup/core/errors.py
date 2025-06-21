"""
🚨 Standardized Error Handling for Frontend Compatibility
========================================================

This module provides standardized error responses that match the frontend's
expected error format and codes.

Error Format:
{
    "error": {
        "code": "ERROR_CODE",
        "message": "Human readable message",
        "details": {}  // Optional additional details
    },
    "timestamp": "ISO 8601 string"
}

Error Codes:
- VALIDATION_ERROR: Invalid input data
- NOT_FOUND: Resource not found
- UNAUTHORIZED: Authentication required
- FORBIDDEN: Access denied
- RATE_LIMITED: Too many requests
- SERVER_ERROR: Internal server error

Author: DevOps Team
Last Updated: January 2025
"""

from fastapi import HTTPException, status
from typing import Dict, Any, Optional
from datetime import datetime
from enum import Enum


class ErrorCode(str, Enum):
    """Standard error codes for frontend compatibility"""
    VALIDATION_ERROR = "VALIDATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    RATE_LIMITED = "RATE_LIMITED"
    SERVER_ERROR = "SERVER_ERROR"
    FORM_NOT_FOUND = "FORM_NOT_FOUND"
    FORM_VALIDATION_ERROR = "FORM_VALIDATION_ERROR"
    FORM_EXPIRED = "FORM_EXPIRED"
    FORM_PRIVATE_ACCESS_DENIED = "FORM_PRIVATE_ACCESS_DENIED"
    FORM_MAX_RESPONSES_REACHED = "FORM_MAX_RESPONSES_REACHED"


class StandardHTTPException(HTTPException):
    """HTTPException with standardized error format"""
    
    def __init__(
        self,
        status_code: int,
        error_code: ErrorCode,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ):
        self.error_code = error_code
        self.error_message = message
        self.error_details = details or {}
        
        # Create standardized detail format
        detail = {
            "error": {
                "code": error_code.value,
                "message": message,
                "details": self.error_details
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        super().__init__(status_code=status_code, detail=detail)


# Convenience functions for common errors
def validation_error(message: str, details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create a validation error response"""
    return StandardHTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        error_code=ErrorCode.VALIDATION_ERROR,
        message=message,
        details=details
    )


def not_found_error(message: str = "Resource not found", details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create a not found error response"""
    return StandardHTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        error_code=ErrorCode.NOT_FOUND,
        message=message,
        details=details
    )


def unauthorized_error(message: str = "Authentication required", details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create an unauthorized error response"""
    return StandardHTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        error_code=ErrorCode.UNAUTHORIZED,
        message=message,
        details=details
    )


def forbidden_error(message: str = "Access denied", details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create a forbidden error response"""
    return StandardHTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        error_code=ErrorCode.FORBIDDEN,
        message=message,
        details=details
    )


def rate_limited_error(message: str = "Too many requests", details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create a rate limited error response"""
    return StandardHTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        error_code=ErrorCode.RATE_LIMITED,
        message=message,
        details=details
    )


def server_error(message: str = "Internal server error", details: Optional[Dict[str, Any]] = None) -> StandardHTTPException:
    """Create a server error response"""
    return StandardHTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code=ErrorCode.SERVER_ERROR,
        message=message,
        details=details
    )


# Form-specific errors
def form_not_found_error(form_id: str) -> StandardHTTPException:
    """Create a form not found error"""
    return StandardHTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        error_code=ErrorCode.FORM_NOT_FOUND,
        message="Form not found",
        details={"form_id": form_id}
    )


def form_validation_error(message: str, field: Optional[str] = None) -> StandardHTTPException:
    """Create a form validation error"""
    details = {"field": field} if field else {}
    return StandardHTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        error_code=ErrorCode.FORM_VALIDATION_ERROR,
        message=message,
        details=details
    )


def form_expired_error(form_id: str, expired_at: str) -> StandardHTTPException:
    """Create a form expired error"""
    return StandardHTTPException(
        status_code=status.HTTP_410_GONE,
        error_code=ErrorCode.FORM_EXPIRED,
        message="Form has expired",
        details={"form_id": form_id, "expired_at": expired_at}
    )


def form_private_access_denied_error(form_id: str) -> StandardHTTPException:
    """Create a private form access denied error"""
    return StandardHTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        error_code=ErrorCode.FORM_PRIVATE_ACCESS_DENIED,
        message="This form is private and requires authorized access",
        details={"form_id": form_id}
    )


def form_max_responses_reached_error(form_id: str, max_responses: int) -> StandardHTTPException:
    """Create a max responses reached error"""
    return StandardHTTPException(
        status_code=status.HTTP_410_GONE,
        error_code=ErrorCode.FORM_MAX_RESPONSES_REACHED,
        message="Form has reached maximum number of responses",
        details={"form_id": form_id, "max_responses": max_responses}
    )


# Response helpers
def success_response(data: Any, message: Optional[str] = None) -> Dict[str, Any]:
    """Create a standardized success response"""
    response = {
        "success": True,
        "data": data,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    if message:
        response["message"] = message
    
    return response


def paginated_response(
    items: list,
    total: int,
    page: int,
    per_page: int,
    message: Optional[str] = None
) -> Dict[str, Any]:
    """Create a standardized paginated response"""
    response = {
        "success": True,
        "data": {
            "items": items,
            "pagination": {
                "total": total,
                "page": page,
                "per_page": per_page,
                "pages": (total + per_page - 1) // per_page,
                "has_next": page * per_page < total,
                "has_prev": page > 1
            }
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    
    if message:
        response["message"] = message
    
    return response
