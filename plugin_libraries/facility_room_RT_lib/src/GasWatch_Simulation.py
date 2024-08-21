from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/api', methods=['POST'])
def handle_request():
    print("Received message: ", request.json)
    data = request.json
    message = data.get('message')
    
    # Interpret the message and create a response
    if message == 'temperature':
        response = {'value': random.random()*0.4+1.8}
    elif message == 'humidity':
        response = {'value': random.randint(0,100)}
    else:
        response = {'value': 'error'}
    
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
