# iOS Profile Server

## Overview

This is a Flask-based web application designed to serve iOS .mobileconfig files for WiFi Passpoint configuration. The application allows users to upload .mobileconfig files and serves them with proper Apple-compatible headers for iOS device installation. The primary use case is distributing WiFi configuration profiles that enable automatic connection to Freedom Wi-Fi hotspots using WPA2/WPA3-Enterprise authentication.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Web Framework
- **Flask**: Chosen as the web framework for its simplicity and lightweight nature
- **ProxyFix middleware**: Handles proxy headers for deployment behind reverse proxies
- **Bootstrap 5**: Frontend styling with dark theme support

### File Management
- **Upload system**: Accepts .mobileconfig files with security validation
- **File storage**: Local filesystem storage in 'uploads' directory
- **Security measures**: File extension validation, secure filename handling, and size limits (16MB max)

### Profile Serving
- **Content-Type handling**: Serves files with 'application/x-apple-aspen-config' MIME type for iOS compatibility
- **Cache control**: Implements no-cache headers to ensure fresh profile downloads
- **Environment configuration**: Uses PROFILE_FILE environment variable to specify active profile

### QR Code Generation
- **qrcode library**: Generates QR codes for easy profile installation
- **Base64 encoding**: QR codes are encoded as base64 images for web display

### User Experience
- **Return page**: Provides post-installation feedback with Universal Link support
- **Flash messaging**: User feedback system for upload status and errors
- **Responsive design**: Mobile-friendly interface using Bootstrap

### Security Features
- **File validation**: Only allows .mobileconfig extensions
- **Secure filenames**: Uses Werkzeug's secure_filename function
- **Session management**: Flask session handling with configurable secret key

## External Dependencies

### Python Libraries
- **Flask**: Web framework and routing
- **qrcode**: QR code generation functionality
- **Werkzeug**: WSGI utilities and security helpers
- **Pathlib**: Modern path handling

### Frontend Dependencies
- **Bootstrap 5**: CSS framework via CDN
- **Bootstrap Icons**: Icon library via CDN
- **Bootstrap Agent Dark Theme**: Replit-specific dark theme styling

### Development Tools
- **Python logging**: Built-in logging for debugging and monitoring

### Deployment Considerations
- **Environment variables**: SESSION_SECRET and PROFILE_FILE configuration
- **Proxy support**: ProxyFix middleware for reverse proxy deployments
- **Static file serving**: Flask handles template and static content serving