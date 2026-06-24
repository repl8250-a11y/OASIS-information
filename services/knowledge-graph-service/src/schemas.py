from pydantic import BaseModel
from typing import Any, List, Optional
from uuid import UUID

class NodeCreate(BaseModel):
    external_id: Optional[str]
    type: str
    properties: dict
    embedding: Optional[List[float]]

class NodeOut(BaseModel):
    id: UUID
    external_id: Optional[str]
    type: str
    properties: dict
    created_at: str

class SearchRequest(BaseModel):
    query_embedding: List[float]
    k: int = 10
