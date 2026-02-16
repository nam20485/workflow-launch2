import React, { useState } from 'react';
import { Shield, Cpu, Database, Activity, CheckCircle2 } from 'lucide-react';

const App = () => {
  const [activeTab, setActiveTab] = useState('arch');
  const components = [
    { name: "Harvester", tech: "Playwright", desc: "Native worker using CDP." },
    { name: "Web UI", tech: "Blazor Server", desc: "Pipeline dashboard." },
    { name: "Data", tech: "Postgres", desc: "Local job storage." }
  ];

  return (
    <div className="p-8 bg-slate-50 min-h-screen font-sans text-slate-900">
      <div className="flex items-center gap-3 mb-8">
        <Shield className="text-blue-600 w-8 h-8" />
        <h1 className="text-2xl font-bold">Job Command Center Strategy</h1>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {components.map((c, i) => (
          <div key={i} className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <span className="text-[10px] uppercase font-bold text-blue-500">{c.tech}</span>
            <h2 className="text-lg font-bold mt-1">{c.name}</h2>
            <p className="text-sm text-slate-500 mt-2">{c.desc}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default App;