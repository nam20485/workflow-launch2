import React, { useState } from 'react';
import { BookOpen, Monitor, Server, Layers, Code, CheckCircle, Terminal, Box, FileText, Cpu, Layout, Activity } from 'lucide-react';

const SpecViewer = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Overview', icon: BookOpen },
    { id: 'requirements', label: 'Requirements', icon: CheckCircle },
    { id: 'tech-stack', label: 'Tech Stack', icon: Code },
    { id: 'architecture', label: 'Architecture', icon: Server },
    { id: 'roadmap', label: 'Roadmap', icon: Activity },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return (
          <div className="space-y-6 animate-in fade-in duration-500">
            <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl p-8 text-white shadow-lg">
              <h1 className="text-3xl font-bold mb-4">EcadRenderView</h1>
              <p className="text-xl opacity-90">
                A high-performance client-server system for parsing, verifying, and rendering proprietary ECAD JSON files.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card title="Core Mission" icon={Monitor}>
                <p className="text-gray-600 mb-4">
                  To provide a robust tool that goes beyond simple viewing by implementing strict logical validation of PCB designs.
                </p>
                <ul className="list-disc pl-5 space-y-2 text-gray-600">
                  <li>Detect 14 specific failure cases.</li>
                  <li>Render with high fidelity (Micron precision).</li>
                  <li>Export to standard formats (PDF/SVG/PNG).</li>
                </ul>
              </Card>

              <Card title="Architecture Style" icon={Layers}>
                <p className="text-gray-600 mb-4">
                  <strong>Thin Client, Smart Server</strong>
                </p>
                <div className="flex flex-col space-y-3">
                  <div className="flex items-center p-3 bg-blue-50 rounded-lg border border-blue-100">
                    <Server className="w-5 h-5 text-blue-600 mr-3" />
                    <div>
                      <span className="font-semibold text-gray-800">Backend (Brain)</span>
                      <p className="text-xs text-gray-500">Parsing, Normalization, Validation, Caching</p>
                    </div>
                  </div>
                  <div className="flex items-center p-3 bg-purple-50 rounded-lg border border-purple-100">
                    <Monitor className="w-5 h-5 text-purple-600 mr-3" />
                    <div>
                      <span className="font-semibold text-gray-800">Frontend (Face)</span>
                      <p className="text-xs text-gray-500">Avalonia UI, SkiaSharp Rendering, User Interaction</p>
                    </div>
                  </div>
                </div>
              </Card>
            </div>
          </div>
        );

      case 'requirements':
        return (
          <div className="space-y-6 animate-in fade-in duration-500">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <RequirementSection title="Parsing & Validation" icon={Terminal}>
                 <ul className="space-y-2 text-sm text-gray-600">
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Ingest proprietary ECAD JSON.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Validate 14 logic rules (e.g., missing layers).</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Return descriptive error codes.</li>
                 </ul>
              </RequirementSection>

              <RequirementSection title="Visualization" icon={Layout}>
                 <ul className="space-y-2 text-sm text-gray-600">
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Render Board Boundary (Clip Path).</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Render Components, Traces, Vias, Keepouts.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Auto-normalize Millimeters to Microns.</li>
                 </ul>
              </RequirementSection>

              <RequirementSection title="User Experience" icon={Monitor}>
                 <ul className="space-y-2 text-sm text-gray-600">
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> 60 FPS Zoom & Pan navigation.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Layer Visibility Toggles.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> High-res raster export (PNG).</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Vector export (PDF/SVG).</li>
                 </ul>
              </RequirementSection>

              <RequirementSection title="DevOps & QA" icon={Box}>
                 <ul className="space-y-2 text-sm text-gray-600">
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Docker container for API.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> Headless UI tests for frontend.</li>
                   <li className="flex items-start"><CheckCircle className="w-4 h-4 mr-2 text-green-500 mt-0.5" /> CI/CD via GitHub Actions.</li>
                 </ul>
              </RequirementSection>
            </div>
          </div>
        );

      case 'tech-stack':
        return (
          <div className="space-y-6 animate-in fade-in duration-500">
            <h3 className="text-xl font-bold text-gray-800 border-b pb-2">Technical Foundations</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <TechCard 
                title="Core" 
                items={['.NET 10.0', 'C# 13', 'EcadRender.Shared']} 
                color="bg-purple-100 text-purple-800"
              />
              <TechCard 
                title="Backend" 
                items={['ASP.NET Core Web API', 'System.Text.Json', 'IMemoryCache', 'Serilog']} 
                color="bg-blue-100 text-blue-800"
              />
              <TechCard 
                title="Frontend" 
                items={['Avalonia UI', 'SkiaSharp', 'CommunityToolkit.Mvvm', 'Polly']} 
                color="bg-indigo-100 text-indigo-800"
              />
              <TechCard 
                title="Testing" 
                items={['xUnit', 'FluentAssertions', 'Moq', 'Avalonia.Headless']} 
                color="bg-green-100 text-green-800"
              />
              <TechCard 
                title="Infrastructure" 
                items={['Docker', 'Docker Compose', 'GitHub Actions']} 
                color="bg-orange-100 text-orange-800"
              />
            </div>
            
            <div className="mt-8">
              <h3 className="text-lg font-semibold mb-3">Project Structure</h3>
              <div className="bg-gray-900 text-gray-300 p-4 rounded-lg font-mono text-sm">
                <p>EcadRenderView.sln</p>
                <p className="pl-4">├── src</p>
                <p className="pl-8">├── EcadRender.Shared <span className="text-gray-500"># DTOs, Enums</span></p>
                <p className="pl-8">├── EcadRender.Api <span className="text-gray-500"># ASP.NET Core API</span></p>
                <p className="pl-8">└── EcadRender.Desktop <span className="text-gray-500"># Avalonia UI Client</span></p>
                <p className="pl-4">└── tests</p>
                <p className="pl-8">├── EcadRender.Api.Tests <span className="text-gray-500"># Backend Unit/Integration</span></p>
                <p className="pl-8">└── EcadRender.Desktop.Tests <span className="text-gray-500"># Headless UI Tests</span></p>
              </div>
            </div>
          </div>
        );

      case 'architecture':
        return (
          <div className="space-y-6 animate-in fade-in duration-500">
            <h3 className="text-xl font-bold text-gray-800">System Data Flow</h3>
            <div className="bg-white p-6 rounded-xl border shadow-sm">
              <div className="flex flex-col space-y-4">
                <FlowStep number="1" title="User Interaction" desc="User selects JSON file in Desktop App." />
                <FlowStep number="2" title="Upload (POST)" desc="File sent to API. Client awaits response." />
                <FlowStep number="3" title="Processing (Server)" desc="API Parses JSON -> Validates (14 Rules) -> Normalizes to Microns -> Caches." />
                <FlowStep number="4" title="Response" desc="Server returns GUID (Success) or Error List (Failure)." />
                <FlowStep number="5" title="Fetch (GET)" desc="Client requests BoardDto using GUID." />
                <FlowStep number="6" title="Rendering (Client)" desc="Avalonia/SkiaSharp renders BoardDto to screen/PDF." />
              </div>
            </div>
          </div>
        );
        
      case 'roadmap':
        return (
          <div className="space-y-6 animate-in fade-in duration-500">
             <div className="relative border-l-2 border-blue-200 ml-4 space-y-8 pb-4">
                <TimelineItem 
                  phase="Phase 0" 
                  title="Scaffolding" 
                  desc="Solution setup, Shared projects, Docker config." 
                />
                <TimelineItem 
                  phase="Phase 1" 
                  title="The Brain (Backend)" 
                  desc="BoardParser, UnitConverter, ValidationEngine (14 Checks), Caching." 
                />
                <TimelineItem 
                  phase="Phase 2" 
                  title="Testing Infra" 
                  desc="xUnit setup, 14 Bad Files fixtures, Headless UI test harness." 
                />
                <TimelineItem 
                  phase="Phase 3" 
                  title="Rendering Core" 
                  desc="BoardRenderer class, SkiaSharp implementation, Coord mapping." 
                />
                <TimelineItem 
                  phase="Phase 4" 
                  title="Desktop UI" 
                  desc="Avalonia Layout, Zoom/Pan Matrix, Layer Toggles, Export Menu." 
                />
                <TimelineItem 
                  phase="Phase 5" 
                  title="CI/CD" 
                  desc="GitHub Actions, Docker Build, Executable publishing." 
                />
                <TimelineItem 
                  phase="Future" 
                  title="Optimization" 
                  desc="gRPC implementation for massive board files." 
                  color="border-purple-200 bg-purple-50"
                />
             </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gray-50 text-gray-900 font-sans">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between shadow-sm">
        <div className="flex items-center space-x-3">
          <div className="bg-blue-600 p-2 rounded-lg">
            <Cpu className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-800">EcadRenderView</h1>
            <p className="text-xs text-gray-500 font-medium">Implementation Specification • v1.0</p>
          </div>
        </div>
        <div className="hidden md:block">
           <span className="bg-green-100 text-green-800 text-xs font-bold px-3 py-1 rounded-full border border-green-200">
             Status: Planning
           </span>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar Navigation */}
        <nav className="w-20 md:w-64 bg-white border-r border-gray-200 flex flex-col py-6">
          <div className="space-y-1 px-3">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center space-x-3 px-3 py-3 rounded-lg transition-colors duration-200 ${
                    isActive
                      ? 'bg-blue-50 text-blue-700 font-medium'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                  }`}
                >
                  <Icon className={`w-5 h-5 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                  <span className="hidden md:inline">{tab.label}</span>
                </button>
              );
            })}
          </div>
        </nav>

        {/* Main Content Area */}
        <main className="flex-1 overflow-y-auto p-6 md:p-10">
          <div className="max-w-5xl mx-auto">
            {renderContent()}
          </div>
        </main>
      </div>
    </div>
  );
};

// Sub-components for cleaner render code
const Card = ({ title, icon: Icon, children }) => (
  <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
    <div className="flex items-center mb-4">
      <div className="p-2 bg-gray-100 rounded-lg mr-3">
        <Icon className="w-5 h-5 text-gray-700" />
      </div>
      <h3 className="font-bold text-lg text-gray-800">{title}</h3>
    </div>
    <div>{children}</div>
  </div>
);

const RequirementSection = ({ title, icon: Icon, children }) => (
  <div className="bg-white p-5 rounded-lg border border-gray-200">
    <div className="flex items-center mb-3">
       <Icon className="w-4 h-4 text-blue-600 mr-2" />
       <h4 className="font-bold text-gray-800">{title}</h4>
    </div>
    {children}
  </div>
);

const TechCard = ({ title, items, color }) => (
  <div className={`p-4 rounded-lg border border-transparent ${color}`}>
    <h4 className="font-bold mb-2 text-sm uppercase tracking-wide opacity-80">{title}</h4>
    <ul className="space-y-1">
      {items.map((item, i) => (
        <li key={i} className="text-sm font-medium">{item}</li>
      ))}
    </ul>
  </div>
);

const FlowStep = ({ number, title, desc }) => (
  <div className="flex items-center group">
    <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-sm border border-blue-200 group-hover:bg-blue-600 group-hover:text-white transition-colors">
      {number}
    </div>
    <div className="ml-4 p-3 flex-1 bg-gray-50 rounded-lg group-hover:bg-blue-50 transition-colors">
      <h4 className="text-sm font-bold text-gray-900">{title}</h4>
      <p className="text-sm text-gray-500">{desc}</p>
    </div>
  </div>
);

const TimelineItem = ({ phase, title, desc, color = "bg-white" }) => (
  <div className="mb-6 ml-6 relative">
    <span className="flex absolute -left-9 justify-center items-center w-6 h-6 bg-blue-100 rounded-full ring-4 ring-white">
      <div className="w-2 h-2 bg-blue-600 rounded-full"></div>
    </span>
    <div className={`p-4 rounded-lg border border-gray-200 shadow-sm ${color}`}>
      <h3 className="flex items-center mb-1 text-lg font-semibold text-gray-900">
        {title} 
        <span className="bg-blue-100 text-blue-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded ml-3">
          {phase}
        </span>
      </h3>
      <p className="text-base font-normal text-gray-500">{desc}</p>
    </div>
  </div>
);

export default SpecViewer;