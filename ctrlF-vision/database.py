from flask import Flask, request, jsonify
import psycopg2

app = Flask(__name__)

# Connect to PostgreSQL Database
conn = psycopg2.connect(
    dbname="ctrlf_db",
    user="admin",
    password="admin",
    host="localhost"
)

@app.route("/store-object", methods=["POST"])
def store_object():
    data = request.json
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO objects (name, x, y, z) VALUES (%s, %s, %s, %s)",
                (data["name"], data["x"], data["y"], data["z"])
            )
            conn.commit()
        return jsonify({"message": "Object stored successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/get-objects", methods=["GET"])
def get_objects():
    with conn.cursor() as cur:
        cur.execute("SELECT name, x, y, z FROM objects")
        objects = [{"name": row[0], "x": row[1], "y": row[2], "z": row[3]} for row in cur.fetchall()]
    return jsonify(objects)

if __name__ == "__main__":
    # app.run(debug=True)
    app.run(host="0.0.0.0", debug=True)