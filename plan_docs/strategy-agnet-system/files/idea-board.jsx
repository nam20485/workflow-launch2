import { useState, useRef, useEffect, useCallback } from "react";

const GOALS = ["💰 Earn Money", "💼 Get Job", "🎯 Both"];
const SPECIFICITY = ["Specific", "General"];
const DOMAINS = ["Consulting", "Freelance", "Employment", "Products", "Content", "Investing", "Other"];

const ACCENT = "#F59E0B";
const NOTION = "#6B7BFF";
const BG = "#0A0A0B";
const SURFACE = "#111113";
const SURFACE2 = "#1A1A1E";
const BORDER = "#2A2A30";
const TEXT = "#E8E8EC";
const MUTED = "#666672";
const SUCCESS = "#10B981";
const ERR = "#EF4444";

// ── Notion property extractor ─────────────────────────────────────────
function extractNotionText(prop) {
  if (!prop) return "";
  if (prop.type === "title") return prop.title?.map(t => t.plain_text).join("") || "";
  if (prop.type === "rich_text") return prop.rich_text?.map(t => t.plain_text).join("") || "";
  if (prop.type === "select") return prop.select?.name || "";
  if (prop.type === "multi_select") return prop.multi_select?.map(s => s.name).join(", ") || "";
  if (prop.type === "checkbox") return prop.checkbox ? "true" : "false";
  if (prop.type === "url") return prop.url || "";
  if (prop.type === "number") return String(prop.number ?? "");
  return "";
}

// Fuzzy-map a Notion page's properties to our idea schema
function mapNotionPage(page) {
  const props = page.properties || {};
  const keys = Object.keys(props);

  const find = (...candidates) => {
    for (const c of candidates) {
      const k = keys.find(k => k.toLowerCase().includes(c.toLowerCase()));
      if (k) return extractNotionText(props[k]);
    }
    return "";
  };

  const text = find("name", "title", "idea", "strategy", "description") || `Notion page ${page.id.slice(0, 8)}`;
  const goal = find("goal", "objective", "target");
  const spec  = find("specific", "type", "kind", "scope");
  const domain = find("domain", "category", "area", "tag");
  const notes = find("notes", "note", "detail", "comment", "rationale", "body");

  const normalizeGoal = (raw) => {
    const r = raw.toLowerCase();
    if (r.includes("money") || r.includes("earn") || r.includes("income")) return "💰 Earn Money";
    if (r.includes("job") || r.includes("employ") || r.includes("hire")) return "💼 Get Job";
    return "🎯 Both";
  };

  const normalizeSpec = (raw) => {
    const r = raw.toLowerCase();
    if (r.includes("spec")) return "Specific";
    return "General";
  };

  const normalizeDomain = (raw) => {
    const r = raw.toLowerCase();
    for (const d of DOMAINS) {
      if (r.includes(d.toLowerCase())) return d;
    }
    return "Other";
  };

  return {
    id: page.id,
    notionId: page.id,
    notionUrl: page.url,
    text,
    goal: normalizeGoal(goal),
    specificity: normalizeSpec(spec),
    domain: normalizeDomain(domain),
    notes,
    pinned: false,
    source: "notion",
  };
}

// ── Notion fetch via Claude API + MCP ────────────────────────────────
async function fetchNotionIdeas(dbId, onStatus) {
  onStatus("Connecting to Notion via Claude + MCP...");

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 8000,
      system: `You are a data extraction assistant. Use the Notion MCP tools to query a database.
After querying, respond ONLY with a valid JSON array of the raw Notion page objects from the results array.
No explanation, no markdown fences, just the raw JSON array starting with [ and ending with ].`,
      messages: [{ role: "user", content: `Query Notion database ID: ${dbId} and return all pages as a JSON array.` }],
      mcp_servers: [{ type: "url", url: "https://mcp.notion.com/mcp", name: "notion" }],
    }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err?.error?.message || `API error ${response.status}`);
  }

  const data = await response.json();
  onStatus("Parsing response...");

  // Try text blocks first
  const textBlocks = data.content.filter(b => b.type === "text").map(b => b.text).join("\n");
  const jsonMatch = textBlocks.match(/\[[\s\S]*\]/);
  if (jsonMatch) {
    try {
      const pages = JSON.parse(jsonMatch[0]);
      if (Array.isArray(pages) && pages.length > 0) return pages.map(mapNotionPage);
    } catch {}
  }

  // Try MCP tool results
  for (const block of data.content.filter(b => b.type === "mcp_tool_result")) {
    const raw = block.content?.[0]?.text || "";
    try {
      const parsed = JSON.parse(raw);
      const pages = parsed.results || (Array.isArray(parsed) ? parsed : null);
      if (pages?.length > 0) return pages.map(mapNotionPage);
    } catch {}
    // try finding array in raw text
    const m = raw.match(/\[[\s\S]*\]/);
    if (m) {
      try {
        const pages = JSON.parse(m[0]);
        if (Array.isArray(pages)) return pages.map(mapNotionPage);
      } catch {}
    }
  }

  throw new Error("Could not parse Notion pages. Check your DB ID and that the integration has access.");
}

// ── Auto-discover databases ───────────────────────────────────────────
async function listNotionDatabases(onStatus) {
  onStatus("Searching your Notion workspace...");

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 4000,
      system: `Use Notion MCP tools to search for all databases. Respond ONLY with a JSON array:
[{"id":"db-id","title":"Database Name","url":"notion-url"}]
No markdown, no explanation.`,
      messages: [{ role: "user", content: "List all Notion databases I have access to." }],
      mcp_servers: [{ type: "url", url: "https://mcp.notion.com/mcp", name: "notion" }],
    }),
  });

  const data = await response.json();

  const all = [
    ...data.content.filter(b => b.type === "text").map(b => b.text),
    ...data.content.filter(b => b.type === "mcp_tool_result").map(b => b.content?.[0]?.text || ""),
  ].join("\n");

  const jsonMatch = all.match(/\[[\s\S]*?\]/);
  if (jsonMatch) {
    try { return JSON.parse(jsonMatch[0]); } catch {}
  }

  for (const block of data.content.filter(b => b.type === "mcp_tool_result")) {
    try {
      const parsed = JSON.parse(block.content?.[0]?.text || "");
      const results = parsed.results || [];
      return results
        .filter(r => r.object === "database")
        .map(r => ({ id: r.id, title: r.title?.[0]?.plain_text || r.id, url: r.url }));
    } catch {}
  }
  return [];
}

// ── Helpers ───────────────────────────────────────────────────────────
function iconBtn(color) {
  return {
    background: "transparent", border: "none", color, cursor: "pointer",
    fontSize: 13, padding: "2px 4px", borderRadius: 3, lineHeight: 1, transition: "color 0.15s",
  };
}

function Chip({ label, color, active }) {
  return (
    <span style={{
      padding: "2px 8px", borderRadius: 3, fontSize: 11, fontFamily: "'JetBrains Mono', monospace",
      fontWeight: 600, letterSpacing: "0.04em", whiteSpace: "nowrap",
      border: `1px solid ${active ? color : BORDER}`,
      background: active ? `${color}22` : "transparent",
      color: active ? color : MUTED,
    }}>{label}</span>
  );
}

// ── IdeaCard ──────────────────────────────────────────────────────────
function IdeaCard({ idea, onUpdate, onDelete, onPin }) {
  const [editing, setEditing] = useState(false);
  const [editText, setEditText] = useState(idea.text);
  const [showNotes, setShowNotes] = useState(false);

  const goalColor = idea.goal === "💰 Earn Money" ? SUCCESS : idea.goal === "💼 Get Job" ? "#60A5FA" : ACCENT;
  const save = () => { onUpdate({ ...idea, text: editText }); setEditing(false); };

  return (
    <div style={{
      background: SURFACE, border: `1px solid ${idea.pinned ? ACCENT + "55" : BORDER}`,
      borderLeft: `3px solid ${goalColor}`, borderRadius: 6,
      padding: "12px 14px", marginBottom: 8,
    }}>
      <div style={{ display: "flex", gap: 6, alignItems: "flex-start", marginBottom: 8 }}>
        <div style={{ flex: 1 }}>
          {editing ? (
            <textarea autoFocus value={editText} onChange={e => setEditText(e.target.value)}
              onKeyDown={e => { if (e.key === "Enter" && e.metaKey) save(); if (e.key === "Escape") setEditing(false); }}
              style={{ width: "100%", background: SURFACE2, border: `1px solid ${ACCENT}`, color: TEXT, borderRadius: 4, padding: "6px 8px", fontFamily: "'JetBrains Mono', monospace", fontSize: 13, resize: "vertical", minHeight: 56, outline: "none" }} />
          ) : (
            <div onClick={() => setEditing(true)}
              style={{ color: TEXT, fontSize: 13, fontFamily: "'JetBrains Mono', monospace", lineHeight: 1.5, cursor: "text" }}>
              {idea.text}
            </div>
          )}
        </div>
        <div style={{ display: "flex", gap: 4, flexShrink: 0, marginTop: 1 }}>
          {idea.notionUrl && (
            <a href={idea.notionUrl} target="_blank" rel="noreferrer" title="Open in Notion"
              style={{ ...iconBtn(NOTION), textDecoration: "none", fontSize: 14 }}>↗</a>
          )}
          <button onClick={() => onPin(idea.id)} style={iconBtn(idea.pinned ? ACCENT : MUTED)}>⚑</button>
          <button onClick={() => setShowNotes(!showNotes)} style={iconBtn(showNotes ? "#60A5FA" : MUTED)}>✎</button>
          {editing && <button onClick={save} style={iconBtn(SUCCESS)}>✓</button>}
          <button onClick={() => onDelete(idea.id)} style={iconBtn(ERR)}>✕</button>
        </div>
      </div>

      <div style={{ display: "flex", gap: 5, flexWrap: "wrap", alignItems: "center" }}>
        <Chip label={idea.goal} color={goalColor} active />
        <Chip label={idea.specificity} color={idea.specificity === "Specific" ? "#A78BFA" : "#FB923C"} active />
        <Chip label={idea.domain} color={MUTED} active />
        {idea.source === "notion" && <Chip label="NOTION" color={NOTION} active />}
        <div style={{ marginLeft: "auto", display: "flex", gap: 3 }}>
          {GOALS.map(g => { const c = g === "💰 Earn Money" ? SUCCESS : g === "💼 Get Job" ? "#60A5FA" : ACCENT;
            return <button key={g} onClick={() => onUpdate({ ...idea, goal: g })}
              style={{ ...iconBtn(idea.goal === g ? c : BORDER), fontSize: 9, padding: "1px 5px", borderRadius: 2, background: idea.goal === g ? `${c}22` : "transparent", fontFamily: "monospace" }}>
              {g.split(" ")[0]}</button>; })}
        </div>
      </div>

      {showNotes && (
        <div style={{ marginTop: 8, fontSize: 11, color: MUTED, fontFamily: "monospace",
          background: SURFACE2, borderRadius: 4, padding: "8px 10px", lineHeight: 1.6,
          border: `1px solid ${BORDER}`, whiteSpace: "pre-wrap" }}>
          {idea.notes || <span style={{ opacity: 0.5 }}>No notes from Notion</span>}
        </div>
      )}
    </div>
  );
}

// ── Notion Panel ──────────────────────────────────────────────────────
function NotionPanel({ onLoad, status, isLoading }) {
  const [dbId, setDbId] = useState("");
  const [databases, setDatabases] = useState([]);
  const [discovering, setDiscovering] = useState(false);
  const [discoverMsg, setDiscoverMsg] = useState("");

  const discover = async () => {
    setDiscovering(true); setDiscoverMsg(""); setDatabases([]);
    try {
      const dbs = await listNotionDatabases(setDiscoverMsg);
      setDatabases(dbs);
      setDiscoverMsg(dbs.length ? `Found ${dbs.length} database${dbs.length !== 1 ? "s" : ""}` : "No databases found — paste your ID below");
    } catch (e) { setDiscoverMsg("Error: " + e.message); }
    setDiscovering(false);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ fontSize: 10, color: NOTION, letterSpacing: "0.15em", fontWeight: 700 }}>▸ NOTION SOURCE</div>

      <button onClick={discover} disabled={discovering} style={{
        width: "100%", background: `${NOTION}18`, border: `1px solid ${NOTION}`,
        color: discovering ? MUTED : NOTION, borderRadius: 5, padding: "9px",
        fontSize: 11, cursor: discovering ? "not-allowed" : "pointer",
        fontFamily: "'JetBrains Mono', monospace", fontWeight: 700, letterSpacing: "0.06em",
      }}>{discovering ? "⟳  DISCOVERING..." : "⬡  AUTO-DISCOVER DATABASES"}</button>

      {discoverMsg && <div style={{ fontSize: 10, color: MUTED, textAlign: "center" }}>{discoverMsg}</div>}

      {databases.length > 0 && (
        <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
          <div style={{ fontSize: 10, color: MUTED, letterSpacing: "0.08em" }}>SELECT DATABASE</div>
          {databases.map(db => (
            <button key={db.id} onClick={() => setDbId(db.id)} style={{
              textAlign: "left", background: dbId === db.id ? `${NOTION}22` : SURFACE2,
              border: `1px solid ${dbId === db.id ? NOTION : BORDER}`,
              color: dbId === db.id ? NOTION : TEXT, borderRadius: 4, padding: "7px 10px",
              fontSize: 11, cursor: "pointer", fontFamily: "monospace",
            }}>
              <div style={{ fontWeight: 700 }}>{db.title}</div>
              <div style={{ fontSize: 9, color: MUTED, marginTop: 2 }}>{db.id}</div>
            </button>
          ))}
        </div>
      )}

      <div>
        <div style={{ fontSize: 10, color: MUTED, letterSpacing: "0.08em", marginBottom: 5 }}>
          {databases.length ? "OR " : ""}PASTE DATABASE ID
        </div>
        <input value={dbId} onChange={e => setDbId(e.target.value.trim())}
          placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
          style={{ width: "100%", background: SURFACE, border: `1px solid ${BORDER}`, color: TEXT, borderRadius: 4, padding: "7px 10px", fontSize: 11, fontFamily: "monospace", outline: "none", boxSizing: "border-box" }}
          onFocus={e => e.target.style.borderColor = NOTION}
          onBlur={e => e.target.style.borderColor = BORDER} />
        <div style={{ fontSize: 9, color: MUTED, marginTop: 4, lineHeight: 1.5 }}>
          From URL: notion.so/.../<span style={{ color: NOTION }}>{"<database-id>"}</span>?v=...
        </div>
      </div>

      <button onClick={() => onLoad(dbId)} disabled={!dbId || isLoading} style={{
        background: dbId && !isLoading ? NOTION : SURFACE2,
        color: dbId && !isLoading ? "#fff" : MUTED,
        border: "none", borderRadius: 6, padding: "10px",
        fontFamily: "'Syne', sans-serif", fontWeight: 800, fontSize: 13,
        letterSpacing: "0.08em", cursor: dbId && !isLoading ? "pointer" : "not-allowed", transition: "all 0.2s",
      }}>{isLoading ? "⟳  LOADING..." : "⬇  LOAD FROM NOTION"}</button>

      {status && (
        <div style={{
          fontSize: 10, fontFamily: "monospace", lineHeight: 1.6, padding: "8px 10px",
          borderRadius: 4, border: `1px solid ${status.startsWith("Error") ? ERR + "44" : NOTION + "44"}`,
          color: status.startsWith("Error") ? ERR : NOTION, background: SURFACE2,
        }}>{status}</div>
      )}
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────────────
let nextLocalId = 9000;

export default function IdeaBoard() {
  const [ideas, setIdeas] = useState([]);
  const [input, setInput] = useState("");
  const [activeGoal, setActiveGoal] = useState("💰 Earn Money");
  const [activeSpec, setActiveSpec] = useState("General");
  const [activeDomain, setActiveDomain] = useState("Other");
  const [filterGoal, setFilterGoal] = useState("All");
  const [filterSpec, setFilterSpec] = useState("All");
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState("pinned");
  const [notionStatus, setNotionStatus] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [tab, setTab] = useState("notion");
  const inputRef = useRef();

  const loadFromNotion = useCallback(async (dbId) => {
    if (!dbId) return;
    setIsLoading(true); setNotionStatus("");
    try {
      const fetched = await fetchNotionIdeas(dbId, setNotionStatus);
      setIdeas(prev => {
        const existing = new Set(prev.filter(i => i.notionId).map(i => i.notionId));
        const newOnes = fetched.filter(f => !existing.has(f.notionId));
        return [...prev, ...newOnes];
      });
      setNotionStatus(`✓ Loaded ${fetched.length} idea${fetched.length !== 1 ? "s" : ""} from Notion`);
    } catch (e) { setNotionStatus("Error: " + e.message); }
    setIsLoading(false);
  }, []);

  const addIdea = () => {
    if (!input.trim()) return;
    setIdeas(prev => [...prev, { id: `local-${nextLocalId++}`, text: input.trim(), goal: activeGoal, specificity: activeSpec, domain: activeDomain, notes: "", pinned: false, source: "user" }]);
    setInput(""); inputRef.current?.focus();
  };

  const updateIdea = u => setIdeas(prev => prev.map(i => i.id === u.id ? u : i));
  const deleteIdea = id => setIdeas(prev => prev.filter(i => i.id !== id));
  const pinIdea = id => setIdeas(prev => prev.map(i => i.id === id ? { ...i, pinned: !i.pinned } : i));

  const filtered = ideas
    .filter(i => filterGoal === "All" || i.goal === filterGoal)
    .filter(i => filterSpec === "All" || i.specificity === filterSpec)
    .filter(i => !search || i.text.toLowerCase().includes(search.toLowerCase()) || (i.notes || "").toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => sortBy === "pinned" ? (b.pinned?1:0)-(a.pinned?1:0) : sortBy === "goal" ? a.goal.localeCompare(b.goal) : (a.source||"").localeCompare(b.source||""));

  const counts = {
    money: ideas.filter(i => i.goal !== "💼 Get Job").length,
    job: ideas.filter(i => i.goal !== "💰 Earn Money").length,
    notion: ideas.filter(i => i.source === "notion").length,
    local: ideas.filter(i => i.source === "user").length,
  };

  return (
    <div style={{ background: BG, minHeight: "100vh", color: TEXT, fontFamily: "'JetBrains Mono', monospace" }}>
      <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Syne:wght@700;800&display=swap" rel="stylesheet" />

      {/* Header */}
      <div style={{ borderBottom: `1px solid ${BORDER}`, padding: "14px 24px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div>
          <div style={{ fontFamily: "'Syne', sans-serif", fontWeight: 800, fontSize: 19, letterSpacing: "-0.02em" }}>
            STRATEGY <span style={{ color: ACCENT }}>IDEABASE</span>
            <span style={{ marginLeft: 10, fontSize: 10, color: NOTION, letterSpacing: "0.1em", fontFamily: "'JetBrains Mono', monospace", verticalAlign: "middle" }}>⬡ NOTION-CONNECTED</span>
          </div>
          <div style={{ fontSize: 10, color: MUTED, marginTop: 2, letterSpacing: "0.08em" }}>GOAL-DIRECTED RESEARCH PIPELINE · INPUT LAYER</div>
        </div>
        <div style={{ display: "flex", gap: 20 }}>
          {[["💰", counts.money, SUCCESS], ["💼", counts.job, "#60A5FA"], ["⬡ N", counts.notion, NOTION], ["✎ L", counts.local, ACCENT], ["∑", ideas.length, TEXT]].map(([sym, n, c]) => (
            <div key={sym} style={{ textAlign: "center" }}>
              <div style={{ color: c, fontWeight: 700, fontSize: 20, lineHeight: 1 }}>{n}</div>
              <div style={{ color: MUTED, fontSize: 9, marginTop: 2 }}>{sym}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ display: "flex", height: "calc(100vh - 63px)" }}>
        {/* Left */}
        <div style={{ width: 300, borderRight: `1px solid ${BORDER}`, display: "flex", flexDirection: "column", flexShrink: 0 }}>
          {/* Tabs */}
          <div style={{ display: "flex", borderBottom: `1px solid ${BORDER}`, flexShrink: 0 }}>
            {[["notion","⬡  NOTION"], ["add","✎  ADD"]].map(([t, label]) => (
              <button key={t} onClick={() => { setTab(t); if (t==="add") setTimeout(()=>inputRef.current?.focus(),50); }} style={{
                flex: 1, padding: "11px 0", border: "none",
                borderBottom: `2px solid ${tab===t ? (t==="notion"?NOTION:ACCENT) : "transparent"}`,
                background: "transparent", color: tab===t ? (t==="notion"?NOTION:ACCENT) : MUTED,
                fontFamily: "'JetBrains Mono', monospace", fontWeight: 700, fontSize: 11,
                letterSpacing: "0.1em", cursor: "pointer",
              }}>{label}</button>
            ))}
          </div>

          <div style={{ flex: 1, overflowY: "auto", padding: 18 }}>
            {tab === "notion" ? (
              <NotionPanel onLoad={loadFromNotion} status={notionStatus} isLoading={isLoading} />
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                <div style={{ fontSize: 10, color: ACCENT, letterSpacing: "0.15em", fontWeight: 700 }}>▸ ADD MANUALLY</div>
                <textarea ref={inputRef} value={input} onChange={e => setInput(e.target.value)}
                  onKeyDown={e => { if (e.key==="Enter" && !e.shiftKey){ e.preventDefault(); addIdea(); } }}
                  placeholder={"Strategy or idea...\n(Enter to add, Shift+Enter for newline)"}
                  style={{ width:"100%", background:SURFACE, border:`1px solid ${BORDER}`, borderRadius:6, padding:"10px 12px", color:TEXT, fontFamily:"'JetBrains Mono', monospace", fontSize:12, resize:"vertical", minHeight:80, outline:"none", boxSizing:"border-box" }}
                  onFocus={e=>e.target.style.borderColor=ACCENT} onBlur={e=>e.target.style.borderColor=BORDER} />

                {[["GOAL", GOALS, activeGoal, setActiveGoal, g => g==="💰 Earn Money"?SUCCESS:g==="💼 Get Job"?"#60A5FA":ACCENT],
                  ["SPECIFICITY", SPECIFICITY, activeSpec, setActiveSpec, s => s==="Specific"?"#A78BFA":"#FB923C"],
                  ["DOMAIN", DOMAINS, activeDomain, setActiveDomain, ()=>ACCENT]].map(([label, opts, active, setter, colorFn]) => (
                  <div key={label}>
                    <div style={{ fontSize:10, color:MUTED, letterSpacing:"0.1em", marginBottom:6 }}>{label}</div>
                    <div style={{ display:"flex", gap:5, flexWrap:"wrap" }}>
                      {opts.map(o => { const c=colorFn(o); return (
                        <button key={o} onClick={()=>setter(o)} style={{ padding:"4px 8px", borderRadius:4, fontSize:10, fontWeight:700, border:`1px solid ${active===o?c:BORDER}`, background:active===o?`${c}22`:"transparent", color:active===o?c:MUTED, cursor:"pointer" }}>{o}</button>
                      );})}
                    </div>
                  </div>
                ))}

                <button onClick={addIdea} disabled={!input.trim()} style={{ background:input.trim()?ACCENT:SURFACE2, color:input.trim()?"#000":MUTED, border:"none", borderRadius:6, padding:"10px", fontFamily:"'Syne', sans-serif", fontWeight:800, fontSize:13, letterSpacing:"0.1em", cursor:input.trim()?"pointer":"not-allowed" }}>
                  + ADD IDEA
                </button>
              </div>
            )}
          </div>

          <div style={{ borderTop:`1px solid ${BORDER}`, padding:"12px 18px", flexShrink:0 }}>
            <button onClick={()=>navigator.clipboard.writeText(JSON.stringify(ideas,null,2))}
              style={{ width:"100%", background:SURFACE2, border:`1px solid ${BORDER}`, color:MUTED, borderRadius:4, padding:"7px", fontSize:10, cursor:"pointer", fontFamily:"monospace" }}>
              📋 EXPORT JSON · {ideas.length} ideas
            </button>
          </div>
        </div>

        {/* Right: list */}
        <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden" }}>
          {/* Filter bar */}
          <div style={{ borderBottom:`1px solid ${BORDER}`, padding:"10px 20px", display:"flex", gap:8, alignItems:"center", flexWrap:"wrap" }}>
            <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search..."
              style={{ background:SURFACE, border:`1px solid ${BORDER}`, color:TEXT, borderRadius:4, padding:"5px 10px", fontSize:11, fontFamily:"monospace", outline:"none", width:140 }} />
            <div style={{ width:1, background:BORDER, height:18, flexShrink:0 }} />
            {["All",...GOALS].map(g => { const c=g==="💰 Earn Money"?SUCCESS:g==="💼 Get Job"?"#60A5FA":g==="🎯 Both"?ACCENT:MUTED;
              return <button key={g} onClick={()=>setFilterGoal(g)} style={{ background:filterGoal===g?`${c}22`:"transparent", border:`1px solid ${filterGoal===g?c:BORDER}`, color:filterGoal===g?c:MUTED, borderRadius:3, padding:"3px 7px", fontSize:10, cursor:"pointer", fontFamily:"monospace", fontWeight:600 }}>{g==="All"?"ALL":g}</button>; })}
            <div style={{ width:1, background:BORDER, height:18, flexShrink:0 }} />
            {["All","Specific","General"].map(s => <button key={s} onClick={()=>setFilterSpec(s)} style={{ background:filterSpec===s?`${MUTED}22`:"transparent", border:`1px solid ${filterSpec===s?MUTED:BORDER}`, color:filterSpec===s?TEXT:MUTED, borderRadius:3, padding:"3px 7px", fontSize:10, cursor:"pointer", fontFamily:"monospace" }}>{s==="All"?"ALL TYPES":s.toUpperCase()}</button>)}
            <div style={{ marginLeft:"auto", display:"flex", gap:5, alignItems:"center" }}>
              <span style={{ fontSize:10, color:MUTED }}>SORT:</span>
              {["pinned","goal","source"].map(s => <button key={s} onClick={()=>setSortBy(s)} style={{ background:sortBy===s?`${ACCENT}22`:"transparent", border:`1px solid ${sortBy===s?ACCENT:BORDER}`, color:sortBy===s?ACCENT:MUTED, borderRadius:3, padding:"3px 7px", fontSize:10, cursor:"pointer", fontFamily:"monospace" }}>{s.toUpperCase()}</button>)}
            </div>
          </div>

          {/* Ideas */}
          <div style={{ flex:1, overflowY:"auto", padding:"16px 20px" }}>
            {ideas.length === 0 ? (
              <div style={{ textAlign:"center", color:MUTED, marginTop:80 }}>
                <div style={{ fontSize:40, marginBottom:16, color:NOTION }}>⬡</div>
                <div style={{ fontSize:13, marginBottom:8 }}>No ideas loaded yet.</div>
                <div style={{ fontSize:11 }}>Auto-discover or paste your <span style={{color:NOTION}}>Notion DB ID</span> to pull your ideas,</div>
                <div style={{ fontSize:11, marginTop:4 }}>or switch to <span style={{color:ACCENT}}>✎ ADD</span> to enter manually.</div>
              </div>
            ) : filtered.length === 0 ? (
              <div style={{ textAlign:"center", color:MUTED, marginTop:60, fontSize:12 }}>No ideas match the current filters.</div>
            ) : filtered.map(idea => (
              <IdeaCard key={idea.id} idea={idea} onUpdate={updateIdea} onDelete={deleteIdea} onPin={pinIdea} />
            ))}
          </div>

          {/* Status bar */}
          <div style={{ borderTop:`1px solid ${BORDER}`, padding:"6px 20px", display:"flex", gap:14, fontSize:10, color:MUTED }}>
            <span>{filtered.length} of {ideas.length} ideas</span>
            <span style={{ color:BORDER }}>|</span>
            <span><span style={{color:NOTION}}>⬡ {counts.notion} Notion</span></span>
            <span style={{ color:BORDER }}>|</span>
            <span>{counts.local} local</span>
            <span style={{ color:BORDER }}>|</span>
            <span style={{color:ACCENT}}>Click text to edit inline · ⚑ pin</span>
          </div>
        </div>
      </div>
    </div>
  );
}
