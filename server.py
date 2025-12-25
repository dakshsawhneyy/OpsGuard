import json
from fastapi import FastAPI
import uvicorn
from pydantic import BaseModel
import requests
from dotenv import load_dotenv
import os
import time

load_dotenv()

# This defines what data the server expects.
class Report(BaseModel):
    cpu: float
    ram: int
    status: str

app = FastAPI()

SLACK_URL = os.getenv("SLACK_URL")
def sendToSlack(msg):
    payload = {"text": msg}     # text for slack and content for discord
    try:
        requests.post(SLACK_URL, json=payload)
        print("Alert send to Slack successfully")
    except Exception as e:
        print("Error Occurred", e)

@app.post("/report")
async def recieve_report(data: Report):
    print(f"Recieved Report: {data}")
    
    if data.status.lower() == "inactive":
        print("ALERT: Nginx is DOWN on the server!")
        # Send alert to slack
        msg = f"{time.time()} -- ALERT: Nginx is DOWN on the server!"
        sendToSlack(msg) 
              
    if data.cpu >= 2.0:
        print(f"Warning: High CPU Activity Detected: {data.cpu}")
    
    if data.ram >= 6000:
        print(f"Warning: High Memory Activity Detected: {data.ram}")
        
    return {"message": "Report Processed", "status": "Success"}
    
# Run as a server
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)