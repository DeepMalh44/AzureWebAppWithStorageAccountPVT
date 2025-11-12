import os
from datetime import datetime
from flask import Flask, render_template, request, flash, redirect, url_for
from werkzeug.utils import secure_filename
from azure.storage.blob import BlobServiceClient
from azure.identity import ManagedIdentityCredential

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Azure Storage configuration
STORAGE_ACCOUNT_NAME = "stfiledevo7bbcldbbn"
CONTAINER_NAME = "uploads"

def get_blob_service_client():
    """Create BlobServiceClient using Managed Identity"""
    account_url = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
    # Use only Managed Identity (no fallback to other credential types)
    credential = ManagedIdentityCredential()
    return BlobServiceClient(account_url=account_url, credential=credential)

@app.route('/')
def index():
    try:
        return render_template('index.html')
    except Exception as e:
        # Fallback if template not found - return simple HTML
        html = """<!DOCTYPE html>
<html>
<head><title>File Upload - Python</title></head>
<body style="font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px;">
    <h1>Python File Upload to Azure Blob Storage</h1>
    <p>Flask + Managed Identity Authentication</p>
    <form method="POST" action="/upload" enctype="multipart/form-data">
        <input type="file" name="file" required style="margin: 20px 0;">
        <br>
        <button type="submit" style="padding: 10px 20px; background: #0078d4; color: white; border: none; cursor: pointer;">Upload to Azure</button>
    </form>
    <p style="color: green;">App is running from wwwroot!</p>
</body>
</html>"""
        return html

@app.route('/upload', methods=['POST'])
def upload_file():
    try:
        # Check if file was uploaded
        if 'file' not in request.files:
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        file = request.files['file']
        
        if file.filename == '':
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        if file:
            # Secure the filename
            filename = secure_filename(file.filename)
            
            # Add timestamp to avoid conflicts
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            blob_name = f"{timestamp}_{filename}"
            
            app.logger.info(f"Uploading file: {filename}, Size: {file.content_length} bytes")
            
            # Upload to Azure Blob Storage using Managed Identity
            blob_service_client = get_blob_service_client()
            container_client = blob_service_client.get_container_client(CONTAINER_NAME)
            
            # Create container if it doesn't exist
            container_client.create_container() if not container_client.exists() else None
            
            # Upload the file
            blob_client = container_client.get_blob_client(blob_name)
            blob_client.upload_blob(file.stream, overwrite=True)
            
            blob_url = blob_client.url
            app.logger.info(f"File uploaded successfully: {blob_url}")
            
            flash(f"File '{filename}' uploaded successfully!", 'success')
            return redirect(url_for('index'))
            
    except Exception as e:
        app.logger.error(f"Error uploading file: {str(e)}")
        flash(f"Error uploading file: {str(e)}", 'error')
        return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
