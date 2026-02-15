import asyncio
import json
import time
from playwright.async_api import async_playwright, Page
from datetime import datetime

# ==========================================
# PHASE 1: THE WATCHER
# Connecting to YOUR existing Chrome instance
# ==========================================

CDP_URL = "http://127.0.0.1:9222"  # Requires Chrome started with --remote-debugging-port=9222

class SemanticWatcher:
    def __init__(self):
        self.session_data = []
        self.is_recording = False

    async def start_watching(self):
        async with async_playwright() as p:
            # Connect to the existing browser session
            try:
                browser = await p.chromium.connect_over_cdp(CDP_URL)
                context = browser.contexts[0]
                page = context.pages[0]  # Attach to active tab
                print(f"✅ Attached to {page.url}")
            except Exception as e:
                print(f"❌ Could not connect to Chrome. Make sure it's running with --remote-debugging-port=9222. Error: {e}")
                return

            self.is_recording = True
            
            # 1. Setup Event Listeners
            # We inject a script into the browser to listen for meaningful interactions
            await page.expose_function("log_interaction", self.handle_interaction)
            
            await page.add_init_script("""
                document.addEventListener('click', (e) => {
                    const target = e.target;
                    // Simple heuristic to get meaningful text
                    const text = target.innerText || target.value || target.getAttribute('aria-label') || '';
                    
                    window.log_interaction({
                        type: 'click',
                        tag: target.tagName,
                        text: text.substring(0, 50), // Truncate
                        id: target.id,
                        className: target.className,
                        path: getXPath(target),
                        timestamp: Date.now()
                    });
                });

                document.addEventListener('change', (e) => {
                     window.log_interaction({
                        type: 'input',
                        tag: e.target.tagName,
                        value: e.target.value,
                        id: e.target.id,
                        timestamp: Date.now()
                    });
                });

                // Helper to generate simple XPath (Crucial for replay)
                function getXPath(element) {
                    if (element.id !== '') return 'id("'+element.id+'")';
                    if (element === document.body) return element.tagName;
                    var ix = 0;
                    var siblings = element.parentNode.childNodes;
                    for (var i=0; i<siblings.length; i++) {
                        var sibling = siblings[i];
                        if (sibling === element) return getXPath(element.parentNode)+'/'+element.tagName+'['+(ix+1)+']';
                        if (sibling.nodeType === 1 && sibling.tagName === element.tagName) ix++;
                    }
                }
            """)
            
            print("👀 Watching... (Press Ctrl+C to stop)")
            
            # Keep the script running to listen for events
            try:
                while True:
                    await asyncio.sleep(1)
            except KeyboardInterrupt:
                print("\n🛑 Stopping Watcher...")
                self.save_session()

    async def handle_interaction(self, data):
        """Callback triggered from the Browser Context"""
        print(f"Captured: {data['type']} on <{data['tag']}> '{data.get('text', '')}'")
        
        # In a real app, here we would grab the AXTree snapshot for context
        # snapshot = await page.accessibility.snapshot()
        
        self.session_data.append(data)

    def save_session(self):
        filename = f"session_{int(time.time())}.json"
        with open(filename, "w") as f:
            json.dump(self.session_data, f, indent=2)
        print(f"💾 Session saved to {filename}")

if __name__ == "__main__":
    watcher = SemanticWatcher()
    asyncio.run(watcher.start_watching())
