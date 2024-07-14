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
        response = {'value': random.randint(20,25)}
    elif message == 'humidity':
        response = {'value': random.randint(0,100)}
    else:
        response = {'value': 'error'}
    
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


# URL = "http://localhost:5000/api",
# io:format("Starting api call to ~p~n",[URL]),
# {ok, {{"HTTP/1.1", 200, "OK"}, _Headers, Body}} = httpc:request(get, {URL, []}, [], []),
# io:format("Response: ~s~n", [Body]),

