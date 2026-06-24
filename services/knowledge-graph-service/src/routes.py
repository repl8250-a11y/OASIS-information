from fastapi import APIRouter, HTTPException
from .schemas import NodeCreate, NodeOut, SearchRequest
from .models import create_node, get_node_by_id, search_nodes

router = APIRouter()

@router.post("/nodes", response_model=NodeOut, status_code=201)
async def post_node(payload: NodeCreate):
    node = await create_node(payload)
    return node

@router.get("/nodes/{node_id}", response_model=NodeOut)
async def get_node(node_id: str):
    node = await get_node_by_id(node_id)
    if not node:
        raise HTTPException(status_code=404, detail="node not found")
    return node

@router.post("/search")
async def search(req: SearchRequest):
    results = await search_nodes(req.query_embedding, k=req.k)
    return {"results": results}
