import os
import logging
from pathlib import Path
from urllib.parse import urljoin, urlparse
import qrcode
import io
import base64
import xml.etree.ElementTree as ET
import re

from flask import Flask, Response, request, render_template, flash, redirect, url_for, jsonify, send_file
from werkzeug.utils import secure_filename
from werkzeug.middleware.proxy_fix import ProxyFix

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create the app
app = Flask(__name__, static_folder='static', static_url_path='/static')
app.secret_key = os.environ.get("SESSION_SECRET", "dev-key-change-in-production")
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'mobileconfig'}
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# Ensure upload directory exists
Path(UPLOAD_FOLDER).mkdir(exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_current_profile_path():
    """Get the path to the currently active profile"""
    profile_name = os.getenv("PROFILE_FILE", "sample.mobileconfig")
    return Path(UPLOAD_FOLDER) / profile_name

def detect_device_type(user_agent):
    """Detect if device is iOS or Android based on User-Agent"""
    if not user_agent:
        return 'unknown'
    
    user_agent = user_agent.lower()
    if 'iphone' in user_agent or 'ipad' in user_agent or 'ios' in user_agent:
        return 'ios'
    elif 'android' in user_agent:
        return 'android'
    else:
        return 'unknown'

def parse_mobileconfig_wifi_data(file_path):
    """Extract WiFi configuration data from .mobileconfig file"""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        # Find WiFi payload
        wifi_data = {
            'ssid': None,
            'password': None,
            'security': 'WPA2',
            'hidden': False
        }
        
        # Navigate through plist structure
        for array in root.findall('.//array'):
            for dict_elem in array.findall('dict'):
                payload_type = None
                for i, child in enumerate(dict_elem):
                    if child.tag == 'key' and child.text == 'PayloadType':
                        next_elem = dict_elem[i + 1] if i + 1 < len(dict_elem) else None
                        if next_elem is not None and next_elem.text == 'com.apple.wifi.managed':
                            payload_type = 'wifi'
                            break
                
                if payload_type == 'wifi':
                    for i, child in enumerate(dict_elem):
                        if child.tag == 'key':
                            next_elem = dict_elem[i + 1] if i + 1 < len(dict_elem) else None
                            if next_elem is not None:
                                if child.text == 'SSID_STR':
                                    wifi_data['ssid'] = next_elem.text
                                elif child.text == 'HIDDEN_NETWORK':
                                    wifi_data['hidden'] = next_elem.tag == 'true'
                                elif child.text == 'EncryptionType':
                                    wifi_data['security'] = next_elem.text
                                elif child.text == 'EAPClientConfiguration':
                                    # Extract username/password from EAP config
                                    for j, eap_child in enumerate(next_elem):
                                        if eap_child.tag == 'key':
                                            eap_next = next_elem[j + 1] if j + 1 < len(next_elem) else None
                                            if eap_next is not None:
                                                if eap_child.text == 'Username':
                                                    wifi_data['username'] = eap_next.text
                                                elif eap_child.text == 'Password':
                                                    wifi_data['password'] = eap_next.text
        
        return wifi_data
    except Exception as e:
        logger.error(f"Error parsing mobileconfig: {e}")
        return None

def generate_wifi_qr_code(wifi_data):
    """Generate WiFi QR code for Android devices"""
    if not wifi_data or not wifi_data.get('ssid'):
        return None
    
    # WiFi QR code format: WIFI:T:<security>;S:<ssid>;P:<password>;H:<hidden>;;
    security = wifi_data.get('security', 'WPA2')
    if security == 'WPA2' or security == 'WPA3':
        security_type = 'WPA'
    elif security == 'WEP':
        security_type = 'WEP'
    else:
        security_type = 'nopass'
    
    ssid = wifi_data.get('ssid', '')
    password = wifi_data.get('password', '')
    hidden = 'true' if wifi_data.get('hidden', False) else 'false'
    
    wifi_string = f"WIFI:T:{security_type};S:{ssid};P:{password};H:{hidden};;"
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(wifi_string)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    img_io = io.BytesIO()
    img.save(img_io, 'PNG')
    img_io.seek(0)
    
    img_base64 = base64.b64encode(img_io.getvalue()).decode()
    return f"data:image/png;base64,{img_base64}"

def generate_qr_code(url):
    """Generate QR code as base64 encoded image"""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    img_io = io.BytesIO()
    img.save(img_io, 'PNG')
    img_io.seek(0)
    
    img_base64 = base64.b64encode(img_io.getvalue()).decode()
    return f"data:image/png;base64,{img_base64}"

@app.route('/')
def index():
    """Main page with upload form and profile management"""
    profile_path = get_current_profile_path()
    profile_exists = profile_path.exists()
    
    # Detect device type
    user_agent = request.headers.get('User-Agent', '')
    device_type = detect_device_type(user_agent)
    
    profile_url = None
    qr_code = None
    wifi_qr_code = None
    wifi_data = None
    
    if profile_exists:
        profile_url = url_for('get_profile', _external=True)
        qr_code = generate_qr_code(profile_url)
        
        # For Android devices, also generate WiFi QR code
        wifi_data = parse_mobileconfig_wifi_data(profile_path)
        if wifi_data and device_type == 'android':
            wifi_qr_code = generate_wifi_qr_code(wifi_data)
    
    # List all uploaded profiles
    uploaded_profiles = []
    if Path(UPLOAD_FOLDER).exists():
        for file in Path(UPLOAD_FOLDER).iterdir():
            if file.suffix.lower() == '.mobileconfig':
                uploaded_profiles.append(file.name)
    
    return render_template('index.html', 
                         profile_exists=profile_exists,
                         profile_url=profile_url,
                         qr_code=qr_code,
                         wifi_qr_code=wifi_qr_code,
                         wifi_data=wifi_data,
                         device_type=device_type,
                         uploaded_profiles=uploaded_profiles,
                         current_profile=os.getenv("PROFILE_FILE", "sample.mobileconfig"))

@app.route('/upload', methods=['POST'])
def upload_profile():
    """Upload a new .mobileconfig file"""
    if 'file' not in request.files:
        flash('No file selected', 'danger')
        return redirect(url_for('index'))
    
    file = request.files['file']
    if file.filename == '' or file.filename is None:
        flash('No file selected', 'danger')
        return redirect(url_for('index'))
    
    if file and file.filename and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = Path(UPLOAD_FOLDER) / filename
        
        try:
            file.save(file_path)
            flash(f'Profile "{filename}" uploaded successfully!', 'success')
            logger.info(f"Profile uploaded: {filename}")
        except Exception as e:
            flash(f'Error uploading file: {str(e)}', 'danger')
            logger.error(f"Upload error: {e}")
    else:
        flash('Invalid file type. Please upload a .mobileconfig file.', 'danger')
    
    return redirect(url_for('index'))

@app.route('/set-active/<filename>')
def set_active_profile(filename):
    """Set the active profile"""
    secure_name = secure_filename(filename)
    profile_path = Path(UPLOAD_FOLDER) / secure_name
    
    if profile_path.exists() and allowed_file(secure_name):
        os.environ["PROFILE_FILE"] = secure_name
        flash(f'Active profile set to "{secure_name}"', 'success')
        logger.info(f"Active profile changed to: {secure_name}")
    else:
        flash('Profile not found', 'danger')
    
    return redirect(url_for('index'))

@app.route('/hs20/profile.mobileconfig')
def get_profile():
    """Serve the iOS profile with Apple-compatible headers"""
    profile_path = get_current_profile_path()
    
    if not profile_path.exists():
        logger.error(f"Profile not found: {profile_path}")
        return Response("Profile not found", status=404)
    
    try:
        data = profile_path.read_bytes()
        filename = profile_path.name
        
        # Apple-compatible headers
        headers = {
            "Content-Type": "application/x-apple-aspen-config",
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Content-Disposition": f'attachment; filename="{filename}"'
        }
        
        logger.info(f"Serving profile: {filename}")
        return Response(data, 
                       mimetype="application/x-apple-aspen-config", 
                       headers=headers)
    
    except Exception as e:
        logger.error(f"Error serving profile: {e}")
        return Response("Error serving profile", status=500)

@app.route('/android/wifi')
def android_wifi():
    """Serve Android WiFi configuration"""
    profile_path = get_current_profile_path()
    
    if not profile_path.exists():
        return Response("Profile not found", status=404)
    
    wifi_data = parse_mobileconfig_wifi_data(profile_path)
    if not wifi_data:
        return Response("Unable to parse WiFi configuration", status=500)
    
    # Generate Android WiFi XML configuration
    xml_config = f"""<?xml version="1.0" encoding="utf-8"?>
<WifiConfiguration>
    <SSID>"{wifi_data.get('ssid', '')}"/>
    <security>{wifi_data.get('security', 'WPA2')}</security>
    <password>{wifi_data.get('password', '')}</password>
    <hiddenSSID>{str(wifi_data.get('hidden', False)).lower()}</hiddenSSID>
</WifiConfiguration>"""
    
    headers = {
        "Content-Type": "application/xml",
        "Content-Disposition": f'attachment; filename="wifi-config.xml"'
    }
    
    return Response(xml_config, mimetype="application/xml", headers=headers)

@app.route('/hs20/return')
def profile_return():
    """Return page after profile installation"""
    return render_template('return.html')

@app.route('/.well-known/apple-app-site-association')
def apple_app_site_association():
    """Apple App Site Association for Universal Links"""
    team_id = os.getenv("APPLE_TEAM_ID", "TEAMID")
    bundle_id = os.getenv("APPLE_BUNDLE_ID", "BUNDLEID")
    
    aasa = {
        "applinks": {
            "apps": [],
            "details": [{
                "appID": f"{team_id}.{bundle_id}",
                "paths": ["/hs20/return"]
            }]
        }
    }
    
    return jsonify(aasa)

@app.route('/delete/<filename>')
def delete_profile(filename):
    """Delete a profile file"""
    secure_name = secure_filename(filename)
    profile_path = Path(UPLOAD_FOLDER) / secure_name
    
    if profile_path.exists():
        try:
            profile_path.unlink()
            flash(f'Profile "{secure_name}" deleted successfully!', 'success')
            logger.info(f"Profile deleted: {secure_name}")
            
            # If this was the active profile, clear the environment variable
            if os.getenv("PROFILE_FILE") == secure_name:
                if "PROFILE_FILE" in os.environ:
                    del os.environ["PROFILE_FILE"]
        except Exception as e:
            flash(f'Error deleting profile: {str(e)}', 'danger')
            logger.error(f"Delete error: {e}")
    else:
        flash('Profile not found', 'danger')
    
    return redirect(url_for('index'))

@app.route('/manifest.json')
def manifest():
    """PWA manifest file"""
    return send_file('static/manifest.json', mimetype='application/manifest+json')

@app.route('/sw.js')
def service_worker():
    """Service worker for PWA"""
    return send_file('static/sw.js', mimetype='application/javascript')

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "iOS Profile Server"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
