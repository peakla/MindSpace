import os
import time
from collections import defaultdict
from flask import Flask, request, jsonify, send_from_directory, Response
from flask_cors import CORS
from elevenlabs.client import ElevenLabs
from functools import wraps

app = Flask(__name__, static_folder='.', static_url_path='')

REPLIT_DEV_DOMAIN = os.environ.get('REPLIT_DEV_DOMAIN', '')
REPLIT_DOMAINS = os.environ.get('REPLIT_DOMAINS', '')

# Build allowed origins from all possible domains
ALLOWED_ORIGINS = [
    'http://localhost:5000',
    'http://127.0.0.1:5000',
]
if REPLIT_DEV_DOMAIN:
    ALLOWED_ORIGINS.append(f'https://{REPLIT_DEV_DOMAIN}')
if REPLIT_DOMAINS:
    for domain in REPLIT_DOMAINS.split(','):
        domain = domain.strip()
        if domain:
            ALLOWED_ORIGINS.append(f'https://{domain}')

CORS(app, resources={
    r"/api/tts/*": {
        "origins": "*",  # Allow all origins for TTS endpoints
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})

ELEVENLABS_API_KEY = os.environ.get('ELEVENLABS_API_KEY')

request_counts = defaultdict(list)
RATE_LIMIT_REQUESTS = 10
RATE_LIMIT_WINDOW = 60

def rate_limit(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        client_ip = request.remote_addr or 'unknown'
        now = time.time()
        
        request_counts[client_ip] = [
            t for t in request_counts[client_ip] 
            if now - t < RATE_LIMIT_WINDOW
        ]
        
        if len(request_counts[client_ip]) >= RATE_LIMIT_REQUESTS:
            return jsonify({
                'error': 'Rate limit exceeded. Please wait before trying again.'
            }), 429
        
        request_counts[client_ip].append(now)
        return f(*args, **kwargs)
    return decorated_function

def check_referer(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        referer = request.headers.get('Referer', '')
        origin = request.headers.get('Origin', '')
        
        # Check against known local domains
        valid = any([
            'localhost' in referer or 'localhost' in origin,
            '127.0.0.1' in referer or '127.0.0.1' in origin,
        ])
        
        # Check dev domain
        if REPLIT_DEV_DOMAIN:
            valid = valid or REPLIT_DEV_DOMAIN in referer or REPLIT_DEV_DOMAIN in origin
        
        # Check all production domains
        if REPLIT_DOMAINS:
            for domain in REPLIT_DOMAINS.split(','):
                domain = domain.strip()
                if domain and (domain in referer or domain in origin):
                    valid = True
                    break
        
        # Also allow if no referer/origin (direct API testing)
        if not referer and not origin:
            valid = True
        
        # Allow any replit.app or replit.dev domains
        if 'replit.app' in referer or 'replit.app' in origin:
            valid = True
        if 'replit.dev' in referer or 'replit.dev' in origin:
            valid = True
        
        if not valid:
            return jsonify({'error': 'Unauthorized request'}), 403
        
        return f(*args, **kwargs)
    return decorated_function

VOICE_MAP = {
    'rachel': 'EXAVITQu4vr4xnSDxMaL',
    'adam': '21m00Tcm4TlvDq8ikWAM',
    'antoni': 'ErXwobaYiN019PkySvjV',
    'arnold': 'VR6AewLTigWG4xSOukaG',
    'bella': 'EXAVITQu4vr4xnSDxMaL',
    'domi': 'AZnzlk1XvdvUeBnXmlld',
    'elli': 'MF3mGyEYCl7XYWbV9V6O',
    'josh': 'TxGEqnHWrfWFTfGW9XjX',
    'sam': 'yoZ06aMxZJJ28mfd3POQ',
}

LANGUAGE_VOICE_MAP = {
    'en': 'rachel',
    'es': 'adam',
    'fr': 'antoni',
    'zh': 'adam',
    'hi': 'adam',
}

@app.route('/')
def serve_index():
    return send_from_directory('.', 'index.html')

@app.route('/community/')
def serve_community():
    return send_from_directory('community', 'index.html')

@app.route('/resourcelib/')
def serve_resourcelib():
    return send_from_directory('resourcelib', 'index.html')

@app.route('/support/')
def serve_support():
    return send_from_directory('support', 'index.html')

@app.route('/blog/')
def serve_blog():
    if os.path.exists('blog/index.html'):
        return send_from_directory('blog', 'index.html')
    return send_from_directory('.', 'index.html')

@app.route('/auth/')
def serve_auth():
    if os.path.exists('auth/index.html'):
        return send_from_directory('auth', 'index.html')
    return send_from_directory('.', 'index.html')

@app.route('/profile/')
def serve_profile():
    return send_from_directory('profile', 'index.html')

@app.route('/terms/')
def serve_terms():
    return send_from_directory('terms', 'index.html')

@app.route('/privacy/')
def serve_privacy():
    return send_from_directory('privacy', 'index.html')

@app.route('/disclaimer/')
def serve_disclaimer():
    return send_from_directory('disclaimer', 'index.html')

@app.route('/docs/')
def serve_docs():
    return send_from_directory('docs', 'index.html')

@app.route('/docs/pdfs/<path:filename>')
def serve_docs_pdfs(filename):
    return send_from_directory('docs/pdfs', filename)

@app.route('/contact/')
def serve_contact():
    if os.path.exists('contact/index.html'):
        return send_from_directory('contact', 'index.html')
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    # Strip trailing slash for directory check
    clean_path = path.rstrip('/')
    
    # Check if path is a directory and serve its index.html
    if os.path.isdir(clean_path):
        index_path = os.path.join(clean_path, 'index.html')
        if os.path.exists(index_path):
            return send_from_directory('.', index_path)
    
    # Serve the file directly if it exists
    if os.path.exists(path):
        return send_from_directory('.', path)
    
    # Fallback to main index.html for SPA-style routing
    return send_from_directory('.', 'index.html')

@app.route('/api/tts/voices', methods=['GET'])
@check_referer
def get_voices():
    voices = [
        {'id': 'rachel', 'name': 'Rachel (Female, Calm)', 'language': 'en'},
        {'id': 'adam', 'name': 'Adam (Male, Deep)', 'language': 'en'},
        {'id': 'antoni', 'name': 'Antoni (Male, Warm)', 'language': 'en'},
        {'id': 'arnold', 'name': 'Arnold (Male, Crisp)', 'language': 'en'},
        {'id': 'domi', 'name': 'Domi (Female, Strong)', 'language': 'en'},
        {'id': 'elli', 'name': 'Elli (Female, Young)', 'language': 'en'},
        {'id': 'josh', 'name': 'Josh (Male, Warm)', 'language': 'en'},
        {'id': 'sam', 'name': 'Sam (Male, Friendly)', 'language': 'en'},
    ]
    return jsonify({'voices': voices, 'available': bool(ELEVENLABS_API_KEY)})

@app.route('/api/tts/generate', methods=['POST'])
@check_referer
@rate_limit
def generate_tts():
    if not ELEVENLABS_API_KEY:
        return jsonify({'error': 'ElevenLabs API key not configured'}), 500
    
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    text = data.get('text', '').strip()
    if not text:
        return jsonify({'error': 'No text provided'}), 400
    
    if len(text) > 5000:
        return jsonify({'error': 'Text too long (max 5000 characters)'}), 400
    
    voice_key = data.get('voice', 'rachel')
    language = data.get('language', 'en')
    
    if voice_key not in VOICE_MAP:
        voice_key = LANGUAGE_VOICE_MAP.get(language, 'rachel')
    
    voice_id = VOICE_MAP.get(voice_key, VOICE_MAP['rachel'])
    
    try:
        client = ElevenLabs(api_key=ELEVENLABS_API_KEY)
        
        audio = client.text_to_speech.convert(
            text=text,
            voice_id=voice_id,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128"
        )
        
        audio_bytes = b''
        for chunk in audio:
            if isinstance(chunk, bytes):
                audio_bytes += chunk
        
        return Response(
            audio_bytes,
            mimetype='audio/mpeg',
            headers={
                'Content-Type': 'audio/mpeg',
                'Cache-Control': 'public, max-age=3600'
            }
        )
        
    except Exception as e:
        error_msg = str(e)
        if 'quota' in error_msg.lower() or 'limit' in error_msg.lower():
            return jsonify({'error': 'API quota exceeded. Please try again later or use browser voice.'}), 429
        return jsonify({'error': f'TTS generation failed: {error_msg}'}), 500

@app.route('/api/tts/health', methods=['GET'])
@check_referer
def tts_health():
    return jsonify({
        'available': bool(ELEVENLABS_API_KEY),
        'service': 'elevenlabs'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
