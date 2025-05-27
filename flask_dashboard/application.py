from flask import Flask, render_template
import boto3
import os

application = Flask(__name__)

DYNAMODB_TABLE = os.getenv("AUDIT_LOG_TABLE", "incident-audit-log")
REGION = os.getenv("REGION", "eu-central-1")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)

@application.route("/")
def dashboard():
    try:
        response = table.scan()
        items = response.get("Items", [])
        items.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return render_template("index.html", items=items)
    except Exception as e:
        return f"Error reading from DynamoDB: {str(e)}", 500

@application.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    application.run(debug=True)
