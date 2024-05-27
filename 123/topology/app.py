#Change to include GET, POST, PUT requests

from flask import Flask, request     # remember to install flask, "sudo pip install flask"

app = Flask(__name__)

#POST request
@app.route('/post', methods=['POST'])
def handle_post():
    data = request.get_data(as_text=True)
    print("Post Message:", data)
    return 'Received POST data:   ' +data + '\n'

#GET request
@app.route('/get', methods =[ 'GET' ])
def handle_get():
    print("GET Message")
    return 'Received GET request\n'

#PUT request
@app.route('/put', methods =[ 'PUT' ])
def handle_put():
    data = request.get_data(as_text = True)
    print("PUT Message")
    return 'Received PUT data:   ' +data+ '\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)