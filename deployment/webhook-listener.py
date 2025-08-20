#!/usr/bin/env python3

"""
Ultra Spec ERP - GitHub Webhook Listener
This script listens for GitHub push events and triggers automatic deployment
"""

import os
import sys
import json
import hmac
import hashlib
import subprocess
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Configuration
WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', 'your-webhook-secret-here')
DEPLOY_SCRIPT_PATH = '/home/frappe/auto-deploy/deploy.sh'
ALLOWED_BRANCHES = ['main', 'master']
PORT = int(os.environ.get('WEBHOOK_PORT', 9000))

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/home/frappe/auto-deploy/webhook.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class WebhookHandler(BaseHTTPRequestHandler):
    
    def do_POST(self):
        """Handle incoming POST requests from GitHub webhooks"""
        
        # Only accept POST requests to /webhook
        if self.path != '/webhook':
            self.send_error(404, "Not Found")
            return
            
        # Get content length
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length == 0:
            self.send_error(400, "No content")
            return
            
        # Read the request body
        body = self.rfile.read(content_length)
        
        # Verify GitHub signature
        if not self.verify_signature(body):
            logger.warning("Invalid signature from %s", self.client_address[0])
            self.send_error(401, "Unauthorized")
            return
            
        try:
            # Parse JSON payload
            payload = json.loads(body.decode('utf-8'))
            
            # Check if this is a push event
            event_type = self.headers.get('X-GitHub-Event', '')
            if event_type != 'push':
                logger.info("Ignoring %s event", event_type)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ignored", "reason": f"Not a push event: {event_type}"}).encode())
                return
                
            # Check if push is to allowed branch
            ref = payload.get('ref', '')
            branch = ref.replace('refs/heads/', '')
            
            if branch not in ALLOWED_BRANCHES:
                logger.info("Ignoring push to branch: %s", branch)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ignored", "reason": f"Branch not allowed: {branch}"}).encode())
                return
                
            # Log the deployment trigger
            commit = payload.get('head_commit', {})
            commit_id = commit.get('id', 'unknown')[:7]
            commit_message = commit.get('message', 'No message')
            author = commit.get('author', {}).get('name', 'Unknown')
            
            logger.info("🚀 Deployment triggered by push to %s", branch)
            logger.info("   Commit: %s", commit_id)
            logger.info("   Author: %s", author)
            logger.info("   Message: %s", commit_message)
            
            # Trigger deployment
            success = self.trigger_deployment()
            
            if success:
                response = {
                    "status": "success",
                    "message": "Deployment triggered successfully",
                    "branch": branch,
                    "commit": commit_id
                }
                self.send_response(200)
                logger.info("✅ Deployment completed successfully")
            else:
                response = {
                    "status": "error",
                    "message": "Deployment failed",
                    "branch": branch,
                    "commit": commit_id
                }
                self.send_response(500)
                logger.error("❌ Deployment failed")
                
        except json.JSONDecodeError:
            logger.error("Invalid JSON payload")
            self.send_error(400, "Invalid JSON")
            return
        except Exception as e:
            logger.error("Error processing webhook: %s", str(e))
            response = {"status": "error", "message": str(e)}
            self.send_response(500)
            
        # Send response
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
        
    def do_GET(self):
        """Handle GET requests for health checks"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "status": "healthy",
                "service": "Ultra Spec ERP Webhook Listener",
                "version": "1.0.0"
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_error(404, "Not Found")
            
    def verify_signature(self, body):
        """Verify GitHub webhook signature"""
        if not WEBHOOK_SECRET:
            logger.warning("No webhook secret configured - skipping signature verification")
            return True
            
        signature_header = self.headers.get('X-Hub-Signature-256', '')
        if not signature_header:
            return False
            
        # Calculate expected signature
        expected_signature = 'sha256=' + hmac.new(
            WEBHOOK_SECRET.encode(),
            body,
            hashlib.sha256
        ).hexdigest()
        
        # Compare signatures
        return hmac.compare_digest(signature_header, expected_signature)
        
    def trigger_deployment(self):
        """Execute the deployment script"""
        try:
            # Check if deployment script exists
            if not os.path.exists(DEPLOY_SCRIPT_PATH):
                logger.error("Deployment script not found: %s", DEPLOY_SCRIPT_PATH)
                return False
                
            # Make sure script is executable
            os.chmod(DEPLOY_SCRIPT_PATH, 0o755)
            
            # Execute deployment script
            logger.info("Executing deployment script: %s", DEPLOY_SCRIPT_PATH)
            
            result = subprocess.run(
                [DEPLOY_SCRIPT_PATH],
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
            
            if result.returncode == 0:
                logger.info("Deployment script completed successfully")
                if result.stdout:
                    logger.info("Script output: %s", result.stdout)
                return True
            else:
                logger.error("Deployment script failed with return code: %d", result.returncode)
                if result.stderr:
                    logger.error("Script error: %s", result.stderr)
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("Deployment script timed out")
            return False
        except Exception as e:
            logger.error("Error executing deployment script: %s", str(e))
            return False
            
    def log_message(self, format, *args):
        """Override default logging to use our logger"""
        logger.info(format % args)

def main():
    """Main function to start the webhook listener"""
    
    # Check if running as frappe user
    if os.getuid() != 0:  # Not root
        try:
            import pwd
            current_user = pwd.getpwuid(os.getuid()).pw_name
            if current_user != 'frappe':
                logger.warning("Not running as frappe user (current: %s)", current_user)
        except:
            pass
    
    # Check if deployment script exists
    if not os.path.exists(DEPLOY_SCRIPT_PATH):
        logger.error("Deployment script not found: %s", DEPLOY_SCRIPT_PATH)
        logger.error("Please ensure the deployment script is in place before starting the webhook listener")
        sys.exit(1)
        
    # Start the HTTP server
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, WebhookHandler)
    
    logger.info("🎧 Ultra Spec ERP Webhook Listener starting...")
    logger.info("   Port: %d", PORT)
    logger.info("   Deployment script: %s", DEPLOY_SCRIPT_PATH)
    logger.info("   Allowed branches: %s", ', '.join(ALLOWED_BRANCHES))
    logger.info("   Health check: http://localhost:%d/health", PORT)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("🛑 Webhook listener stopped by user")
    except Exception as e:
        logger.error("Error running webhook listener: %s", str(e))
        sys.exit(1)
    finally:
        httpd.server_close()

if __name__ == '__main__':
    main()

