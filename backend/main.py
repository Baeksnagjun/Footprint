from __future__ import annotations

import math
import random
import string
import time
import uuid
from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, model_validator

app = FastAPI(title="Footprint API", version="0.4.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 한성대학교 캠퍼스 (iOS FootprintConfig 와 동일)
CAMPUS_CENTER_LAT = 37.58261
CAMPUS_CENTER_LNG = 127.01054
CAMPUS_RADIUS_METERS = 330

locations: Dict[str, dict] = {}
campus_entry_events: List[dict] = []
groups: Dict[str, dict] = {}
invite_codes: Dict[str, str] = {}
messages: Dict[str, List[dict]] = {}
MAX_MESSAGES_PER_THREAD = 200


class LocationUpdate(BaseModel):
    user_id: str = Field(min_length=1, max_length=64)
    lat: float
    lng: float
    name: Optional[str] = None
    group_id: Optional[str] = None


class CreateGroupRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=64)
    user_name: Optional[str] = Field(default=None, min_length=1, max_length=32)
    group_name: Optional[str] = Field(default=None, min_length=1, max_length=32)
    name: Optional[str] = Field(default=None, min_length=1, max_length=32)
    university: Optional[str] = None

    @model_validator(mode="after")
    def resolve_names(self) -> "CreateGroupRequest":
        resolved_user = (self.user_name or self.name or "").strip()
        resolved_group = (self.group_name or self.name or "그룹").strip()
        if not resolved_user:
            raise ValueError("user_name 또는 name이 필요합니다.")
        if not resolved_group:
            raise ValueError("group_name이 필요합니다.")
        self.user_name = resolved_user
        self.group_name = resolved_group
        return self


class JoinGroupRequest(BaseModel):
    invite_code: str = Field(min_length=4, max_length=8)
    user_id: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=32)


class InviteRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=64)


class SendMessageRequest(BaseModel):
    from_user_id: str = Field(min_length=1, max_length=64)
    to_user_id: str = Field(min_length=1, max_length=64)
    text: str = Field(min_length=1, max_length=500)


def is_on_campus(lat: float, lng: float) -> bool:
    dlat = (lat - CAMPUS_CENTER_LAT) * 111_320
    dlng = (lng - CAMPUS_CENTER_LNG) * 111_320 * math.cos(math.radians(CAMPUS_CENTER_LAT))
    return math.hypot(dlat, dlng) <= CAMPUS_RADIUS_METERS


def generate_invite_code() -> str:
    alphabet = string.ascii_uppercase + string.digits
    for _ in range(50):
        code = "".join(random.choices(alphabet, k=6))
        if code not in invite_codes:
            return code
    return uuid.uuid4().hex[:6].upper()


def get_group(group_id: str) -> dict:
    group = groups.get(group_id)
    if not group:
        raise HTTPException(status_code=404, detail="그룹을 찾을 수 없습니다.")
    return group


def ensure_member(group_id: str, user_id: str) -> None:
    group = get_group(group_id)
    if user_id not in group["members"]:
        raise HTTPException(status_code=403, detail="그룹 멤버만 할 수 있습니다.")


def add_member_to_group(group_id: str, user_id: str, name: str) -> None:
    group = get_group(group_id)
    group["members"][user_id] = {"user_id": user_id, "name": name}


def user_is_group_member(user_id: str, group_id: Optional[str]) -> bool:
    if not group_id:
        return False
    group = groups.get(group_id)
    if not group:
        return False
    return user_id in group.get("members", {})


def location_matches_group(user_id: str, group_id: Optional[str]) -> bool:
    if not group_id:
        return False
    return user_is_group_member(user_id, group_id)


def campus_entry_matches_group(event: dict, group_id: Optional[str]) -> bool:
    if not group_id:
        return False
    return user_is_group_member(event.get("user_id", ""), group_id)


def group_summary(group_id: str, group: dict) -> dict:
    return {
        "group_id": group_id,
        "group_name": group.get("group_name", "그룹"),
        "member_count": len(group.get("members", {})),
    }


def group_payload(group_id: str, include_invite_code: bool = False) -> dict:
    group = get_group(group_id)
    payload = {
        "group_id": group_id,
        "group_name": group.get("group_name", "그룹"),
        "members": members_payload(group_id),
    }
    if include_invite_code and group.get("invite_code"):
        payload["invite_code"] = group["invite_code"]
    return payload


def record_campus_entry(user_id: str, name: str, group_id: Optional[str] = None) -> Optional[dict]:
    event = {
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "name": name,
        "group_id": group_id,
        "message": f"{name}님이 학교에 입장하였습니다",
        "entered_at": time.time(),
    }
    campus_entry_events.append(event)
    if len(campus_entry_events) > 100:
        del campus_entry_events[:-100]
    return event


def members_payload(group_id: str) -> List[dict]:
    group = get_group(group_id)
    return list(group["members"].values())


def thread_id(group_id: str, user_a: str, user_b: str) -> str:
    a, b = sorted([user_a, user_b])
    return f"{group_id}:{a}:{b}"


def message_payload(message: dict) -> dict:
    return {
        "message_id": message["message_id"],
        "from_user_id": message["from_user_id"],
        "to_user_id": message["to_user_id"],
        "text": message["text"],
        "sent_at": message["sent_at"],
    }


@app.get("/health")
def health() -> dict:
    on_campus = sum(1 for data in locations.values() if data.get("is_on_campus"))
    return {
        "status": "ok",
        "api_version": "0.4.0",
        "users_online": len(locations),
        "on_campus": on_campus,
        "groups": len(groups),
    }


@app.get("/users/{user_id}/groups")
def list_user_groups(user_id: str) -> dict:
    result = []
    for group_id, group in groups.items():
        if user_id in group.get("members", {}):
            result.append(group_summary(group_id, group))
    result.sort(key=lambda item: item["group_name"])
    return {"groups": result}


@app.get("/groups/{group_id}")
def get_group_detail(group_id: str) -> dict:
    return group_payload(group_id)


@app.post("/groups")
def create_group(payload: CreateGroupRequest) -> dict:
    group_id = str(uuid.uuid4())
    groups[group_id] = {
        "group_id": group_id,
        "group_name": payload.group_name.strip(),
        "invite_code": None,
        "university": payload.university,
        "created_at": time.time(),
        "members": {},
    }
    add_member_to_group(group_id, payload.user_id, payload.user_name)
    return group_payload(group_id)


@app.post("/groups/{group_id}/invite")
def issue_invite(group_id: str, payload: InviteRequest) -> dict:
    ensure_member(group_id, payload.user_id)
    group = get_group(group_id)
    if not group.get("invite_code"):
        code = generate_invite_code()
        group["invite_code"] = code
        invite_codes[code] = group_id
    return {
        "group_id": group_id,
        "group_name": group.get("group_name", "그룹"),
        "invite_code": group["invite_code"],
    }


@app.post("/groups/join")
def join_group(payload: JoinGroupRequest) -> dict:
    code = payload.invite_code.strip().upper()
    group_id = invite_codes.get(code)
    if not group_id:
        raise HTTPException(status_code=404, detail="초대 코드를 찾을 수 없습니다.")
    add_member_to_group(group_id, payload.user_id, payload.name)
    return group_payload(group_id)


@app.get("/groups/{group_id}/members")
def get_group_members(group_id: str) -> dict:
    return {"members": members_payload(group_id)}


@app.post("/groups/{group_id}/messages")
def send_message(group_id: str, payload: SendMessageRequest) -> dict:
    ensure_member(group_id, payload.from_user_id)
    ensure_member(group_id, payload.to_user_id)
    if payload.from_user_id == payload.to_user_id:
        raise HTTPException(status_code=400, detail="자신에게는 메시지를 보낼 수 없습니다.")

    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="메시지를 입력해주세요.")

    tid = thread_id(group_id, payload.from_user_id, payload.to_user_id)
    message = {
        "message_id": str(uuid.uuid4()),
        "from_user_id": payload.from_user_id,
        "to_user_id": payload.to_user_id,
        "text": text,
        "sent_at": time.time(),
    }
    thread = messages.setdefault(tid, [])
    thread.append(message)
    if len(thread) > MAX_MESSAGES_PER_THREAD:
        messages[tid] = thread[-MAX_MESSAGES_PER_THREAD:]
    return message_payload(message)


@app.get("/groups/{group_id}/messages")
def get_messages(
    group_id: str,
    user_id: str = Query(..., min_length=1, max_length=64),
    with_user: str = Query(..., min_length=1, max_length=64),
    since: Optional[float] = Query(default=None),
) -> dict:
    ensure_member(group_id, user_id)
    ensure_member(group_id, with_user)
    tid = thread_id(group_id, user_id, with_user)
    thread = messages.get(tid, [])
    if since is not None:
        thread = [item for item in thread if item["sent_at"] > since]
    return {"messages": [message_payload(item) for item in thread]}


@app.get("/groups/{group_id}/messages/inbox")
def get_message_inbox(
    group_id: str,
    user_id: str = Query(..., min_length=1, max_length=64),
    since: Optional[float] = Query(default=None),
) -> dict:
    ensure_member(group_id, user_id)
    group = get_group(group_id)
    members = group.get("members", {})
    prefix = f"{group_id}:"
    results = []
    for tid, thread in messages.items():
        if not tid.startswith(prefix):
            continue
        for item in thread:
            if item["to_user_id"] != user_id:
                continue
            if since is not None and item["sent_at"] <= since:
                continue
            sender = members.get(item["from_user_id"], {})
            payload = message_payload(item)
            payload["from_name"] = sender.get("name", item["from_user_id"])
            results.append(payload)
    results.sort(key=lambda item: item["sent_at"])
    return {"messages": results}


@app.post("/location")
def update_location(payload: LocationUpdate) -> dict:
    now = time.time()
    on_campus = is_on_campus(payload.lat, payload.lng)
    previous = locations.get(payload.user_id, {})
    was_on_campus = previous.get("is_on_campus", False)
    name = payload.name or payload.user_id
    group_id = payload.group_id
    if not group_id:
        raise HTTPException(status_code=400, detail="그룹에 참여한 후 위치를 공유할 수 있습니다.")
    if not user_is_group_member(payload.user_id, group_id):
        raise HTTPException(status_code=403, detail="이 그룹의 멤버만 위치를 공유할 수 있습니다.")

    entered_campus = False
    if on_campus and not was_on_campus:
        record_campus_entry(payload.user_id, name, group_id)
        entered_campus = True

    locations[payload.user_id] = {
        "user_id": payload.user_id,
        "name": name,
        "lat": payload.lat,
        "lng": payload.lng,
        "updated_at": now,
        "is_on_campus": on_campus,
        "group_id": group_id,
    }

    if group_id and group_id in groups:
        add_member_to_group(group_id, payload.user_id, name)

    return {
        "ok": True,
        "is_on_campus": on_campus,
        "entered_campus": entered_campus,
    }


@app.get("/locations")
def get_locations(
    except_user: Optional[str] = Query(default=None),
    group_id: Optional[str] = Query(default=None),
) -> dict:
    if not group_id or group_id not in groups:
        return {"peers": [], "campus_entries": [], "members": []}

    peers = []
    now = time.time()
    stale_after = 120

    for user_id, data in locations.items():
        if except_user and user_id == except_user:
            continue
        if not location_matches_group(user_id, group_id):
            continue
        if now - data["updated_at"] > stale_after:
            continue
        on_campus = data.get("is_on_campus", False)
        peers.append(
            {
                "user_id": data["user_id"],
                "name": data["name"],
                "lat": data["lat"],
                "lng": data["lng"],
                "updated_at": data["updated_at"],
                "is_on_campus": on_campus,
            }
        )

    recent_entries = []
    for event in campus_entry_events:
        if now - event["entered_at"] > 90:
            continue
        if except_user and event["user_id"] == except_user:
            continue
        if not campus_entry_matches_group(event, group_id):
            continue
        recent_entries.append(event)

    members = members_payload(group_id)

    return {"peers": peers, "campus_entries": recent_entries, "members": members}


@app.delete("/location/{user_id}")
def clear_location(user_id: str) -> dict:
    locations.pop(user_id, None)
    return {"ok": True}
