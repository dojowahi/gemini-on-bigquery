
import os

import functions_framework
from flask import jsonify
from google import genai
from google.genai.types import GenerateContentConfig, Part

PROJECT_ID = os.environ.get("PROJECT_ID",'gen-ai-4all')
LOCATION = os.environ.get("GOOGLE_CLOUD_REGION", "us-central1")
print(f"PROJECT_ID,{PROJECT_ID}")
client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)

@functions_framework.http
def list_url(request) -> str | tuple[str, int]:
    print(f"Request:{request}")
    request_json = request.get_json()
    if not isinstance(request_json, dict) or "calls" not in request_json:
        raise ValueError("Invalid request: 'calls' key missing or not a dictionary.")
    calls = request_json["calls"]
    print(f"Call length:{len(calls)}")
    print(f"Calls:{calls}")
    for call in calls:
        image_url = str(call[0])
        print(image_url)
    return image_url
    

def analyze_image(image_file) -> str | None:

    prompt = "Analyze the image?"
        
    response_schema = {
"type": "object",
"properties": {
    "TagLine": {
        "type": "string",
        "description": "Suggest a tag line"
    }
},
}
    image = Part.from_uri(file_uri=image_file, mime_type="image/jpg")
    response = client.models.generate_content(
        model='gemini-1.5-pro',
        contents=[
            image,
            prompt,
        ],
        config=GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=response_schema,
        ),
    )

        # response = client.models.generate_content(
        #     model='gemini-1.5-pro',
        #     contents=[
        #         image,
        #         prompt,
        #     ],
        # )
    # output = " ".join(response.text.strip().split("\n")) if response.text else "No text generated."
    # print(output)
    print(f"response:{response}")
    return response.text
    

def run_it(request) -> str | tuple[str, int]:
    try:
        file_to_analyze = list_url(request)
        
        image_description = analyze_image(file_to_analyze)
        result = image_description or "Unable to generate description"
        return jsonify({"replies": [str(result)]})
    except Exception as e:
        return jsonify({"errorMessage": "Error in run_it: " + str(e)}), 400
