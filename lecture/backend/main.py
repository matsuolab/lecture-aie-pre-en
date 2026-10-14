from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from dotenv import load_dotenv
load_dotenv()

app = FastAPI()

# CORS setting
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

router = APIRouter()

class MessageRequest(BaseModel):
    input_text: str
    
@router.post("/app/api")
def api_endpoint(req: MessageRequest):
    if os.getenv('PROVIDER') == "mock":
        print(os.getenv('PROVIDER'))
        return {
        "status": "mock",
        "reply": f"{os.getenv('PROVIDER')}_mock_mode",
        }

    else:
        return {
        "status": "success",
        "reply": f"{req.input_text}は{len(req.input_text)}文字です。",
        }


    
app.include_router(router)