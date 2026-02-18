# **Architecture Overview: ODB++ Viewer**

Version: 4.1  
Date: 2025-10-21

## **1\. Overview**

This document details the software architecture for the ODB++ Desktop Viewer. The system is designed as a client-server application.

* **Client:** A cross-platform desktop application built with .NET 10 and Avalonia UI. It is responsible for the user interface, interaction, and 3D rendering.  
* **Server:** The existing OdbDesignServer, which parses ODB++ design files and exposes the data through a **gRPC API**.  
* **Communication:** The client and server communicate over HTTP/2 using **gRPC**, with data payloads serialized as **Protocol Buffers (Protobuf)**. This approach is significantly more performant than REST/JSON as it bypasses an expensive JSON serialization step on the server and a JSON deserialization step on the client. This architecture was specifically chosen to replace a previous REST/JSON implementation, directly targeting and eliminating known performance bottlenecks related to large-scale JSON text processing on both the client and server.

## **2\. Technology Stack**

* **Core Framework:** .NET 10  
* **UI Framework:** Avalonia UI  
* **MVVM Framework:** CommunityToolkit.Mvvm  
* **3D Graphics:** Helix Toolkit for Avalonia  
* **API/RPC Client:** **Grpc.Net.Client**, **Google.Protobuf**, **Grpc.Tools** (for .proto code generation)  
* **Geometry Processing:** **NetTopologySuite** \- Essential for handling complex ODB++ Surface features.  
* **Numerical Computing:** **MathNet.Numerics** \- Used for coordinate transformations.  
* **Logging:** **Serilog** \- For structured and configurable logging.

## **3\. Client Architecture (MVVM)**

The application strictly follows the Model-View-ViewModel (MVVM) pattern.

#### **Model**

* Represents the raw data of the application.  
* These are **C\# classes auto-generated from .proto files** using the Grpc.Tools NuGet package. This ensures the client and server models are always perfectly synchronized.  
* The .proto definition file (e.g., features.proto, odb\_api.proto) will be the single source of truth for the data contract.

#### **View**

* Defines the UI structure using .axaml files (Avalonia's XAML).  
* Key Views: MainView.axaml, ViewportView.axaml, LayerPanelView.axaml, InfoPanelView.axaml.

#### **ViewModel**

* Acts as the intermediary, containing all presentation logic and state management.  
* Exposes data from the Model via observable properties (\[ObservableProperty\]) and actions via commands (\[RelayCommand\]).  
* Key ViewModels: MainViewModel, ViewportViewModel, LayerViewModel.

#### **Services**

* **OdbDesignGrpcService:** A singleton service encapsulating all gRPC communication. It manages the gRPC channel and the auto-generated client stub. It will expose methods that call the server's RPCs, such as async IAsyncEnumerable\<FeatureRecord\> GetFeaturesAsync(LayerRequest request, CancellationToken token), which wraps the underlying server-streaming RPC call.  
* **GeometryFactory:** A service responsible for translating the auto-generated Model objects into Visual3D objects for Helix Toolkit.

## **4\. Backend Communication (gRPC)**

### **gRPC Service Interaction**

* **Contract:** The API is strictly defined in a .proto file (e.g., odb\_api.proto) shared between the client and server.  
* **Service Example (odb\_api.proto):**  
  syntax \= "proto3";  
  package Odb.Lib.Protobuf;

  import "featuresfile.proto"; // Contains FeatureRecord definition  
  import "layerdirectory.proto"; // Contains LayerRecord definition

  // Service definition for ODB++ data access  
  service OdbDesignApi {  
    // Server-streaming RPC to efficiently send large feature sets for a specific layer  
    rpc GetLayerFeaturesStream(LayerRequest) returns (stream FeatureRecord);

    // Unary RPC to get the list of layers for a specific step  
    rpc GetLayerList(StepRequest) returns (LayerDirectory);  
  }

  // Request message for layer features  
  message LayerRequest {  
    string file\_model\_name \= 1; // Identifier for the loaded design  
    string step\_name \= 2;       // Name of the step within the design  
    string layer\_name \= 3;      // Name of the layer  
  }

  // Request message for step information (e.g., list of layers)  
  message StepRequest {  
     string file\_model\_name \= 1; // Identifier for the loaded design  
     string step\_name \= 2;       // Name of the step  
  }

* **Transport:** gRPC uses HTTP/2 for persistent, multiplexed connections, reducing latency.  
* **Authentication:** Can be handled via gRPC interceptors to add credentials (e.g., Basic Auth headers) to each call metadata.

### **Key Data Structures (Protobuf Messages)**

* All data models (FeaturesFile, FeatureRecord, SymbolName, LayerDirectory, LayerRecord, etc.) are defined as message types in the shared .proto files.  
* The FeatureRecord uses a oneof field to represent the discriminated union of different feature types (Pad, Line, Surface, etc.). See Appendix for details.  
* **Coordinates:** All coordinate values are provided in **inches**.

## **5\. Data Flow (gRPC File Loading)**

This flow eliminates the JSON conversion bottlenecks on both the client and server.

1. **User Action:** User clicks "Load File" in the MainView.  
2. **Command Execution:** The MainViewModel's LoadFileCommand is executed, setting IsLoading \= true.  
3. **gRPC Call (Metadata):** ViewModel potentially calls a unary RPC first (e.g., GetLayerList) to retrieve the layer structure for the selected step.  
4. **gRPC Call (Features):** The ViewModel invokes the OdbDesignGrpcService on a background thread. It makes a server-streaming RPC call, e.g., GetLayerFeaturesStream(request) for each layer it needs to display.  
5. **Binary Streaming & Deserialization:** The client receives a stream of binary FeatureRecord Protobuf messages. The Grpc.Net.Client library automatically and efficiently deserializes these into the strongly-typed C\# objects.  
6. **ViewModel Update (Incremental):** The ViewModel can process each FeatureRecord *as it arrives on the stream*. This allows for progressive rendering and a more responsive UI, as the application doesn't have to wait for the entire dataset to download.  
7. **Scene Generation:** The GeometryFactory service is called for each feature record (or in batches) to create Visual3D objects.  
8. **Rendering:** The HelixViewport3D control is updated as new Visual3D objects are generated.  
9. **Finalization:** The MainViewModel sets IsLoading \= false once the gRPC stream(s) have completed.

## **6\. Appendix: Key Protocol Buffer Definitions**

These definitions are extracted from the .proto files within the OdbDesignLib/protoc directory of the OdbDesign repository. They form the core data contract between the gRPC server and client.

// Common geometric and enum types (from common.proto, enums.proto)

syntax \= "proto3";  
package Odb.Lib.Protobuf;

// Represents a 2D point  
message Point {  
  double x \= 1;  
  double y \= 2;  
}

// Represents a part of a contour polygon (line or arc segment)  
message PolygonPart {  
  Point end\_point \= 1;  
  double center\_x \= 2; // Only used if type is Arc  
  double center\_y \= 3; // Only used if type is Arc  
  bool clockwise \= 4;  // Only used if type is Arc  
}

// Represents a closed contour, potentially with holes  
message ContourPolygon {  
  repeated PolygonPart outline \= 1; // The outer boundary  
  repeated ContourPolygon holes \= 2; // Inner boundaries representing holes  
  ContourPolygonType type \= 3;       // Island or Hole  
}

// Defines the polarity of a feature  
enum Polarity {  
  POSITIVE \= 0; // Material is present  
  NEGATIVE \= 1; // Material is absent (cutout)  
}

// Type of contour polygon part  
enum ContourPolygonType {  
  ISLAND \= 0; // Represents filled area  
  HOLE \= 1;   // Represents cutout area  
}

// Defines the type of ODB++ feature  
enum FeatureType {  
  ARC \= 0;  
  PAD \= 1;  
  SURFACE \= 2;  
  // BARCODE \= 3; // Often unused or minimal implementation  
  TEXT \= 4;  
  LINE \= 5;  
}

// \-------------------------------------------------------------------  
// Feature Record definition (from featuresfile.proto)

message FeatureRecord {  
  // Common fields for all feature types  
  uint32 id \= 1;  
  uint32 sym\_num \= 2;             // Symbol number reference  
  Point location \= 3;             // Primary location (center for pad/arc, start for line)  
  Polarity polarity \= 4;          // Positive or Negative  
  uint32 d\_code \= 5;              // D-code reference  
  uint32 orient\_def \= 6;          // Orientation definition (complex)  
  float rotation \= 7;             // Rotation in degrees  
  float scale \= 8;                // Scale factor  
  bool mirror \= 9;                // Mirror flag  
  uint32 ns\_att\_index \= 10;       // Attribute index  
  uint32 property\_mask \= 11;      // Bitmask for properties  
  float apt\_def\_resize\_factor \= 12; // Aperture resize factor

  // Type-specific data using 'oneof'  
  oneof feature\_specific\_data {  
    ArcData arc\_data \= 13;  
    PadData pad\_data \= 14;  
    LineData line\_data \= 15;  
    SurfaceData surface\_data \= 16;  
    TextData text\_data \= 17;  
  }  
}

// Specific data for ARC features  
message ArcData {  
  Point end\_location \= 1;  
  Point center\_location \= 2;  
  bool clockwise \= 3;  
}

// Specific data for PAD features (often relies mostly on symbol definition)  
message PadData {  
  // Pads are primarily defined by their symbol (sym\_num)  
  // Specific overrides might appear here if needed, but often empty.  
}

// Specific data for LINE features  
message LineData {  
  Point end\_location \= 1;  
}

// Specific data for SURFACE features  
message SurfaceData {  
  ContourPolygon polygon\_data \= 1;  
}

// Specific data for TEXT features  
message TextData {  
  string text\_string \= 1;  
  // Font, size, etc., are often linked via symbol or attributes  
}

// \-------------------------------------------------------------------  
// Symbol Name definition (from symbolname.proto)

message SymbolName {  
  string name \= 1;          // Name of the symbol  
  string library \= 2;       // Library the symbol belongs to  
  string units \= 3;         // Units used in symbol definition (e.g., "inch")  
  SymbolType type \= 4;      // Type of symbol (e.g., Standard, Custom)  
  uint32 form \= 5;          // Form identifier (complex)  
  repeated float points \= 6; // Geometric points defining the symbol (packed array)  
}

enum SymbolType {  
  STANDARD \= 0;  
  CUSTOM \= 1;  
  // Other types as defined in ODB++ spec  
}

// \-------------------------------------------------------------------  
// Layer Directory and Record (from layerdirectory.proto)

message LayerRecord {  
    string name \= 1;  
    LayerType type \= 2;  
    LayerContext context \= 3;  
    Polarity polarity \= 4;  
    uint32 attribute\_list\_id \= 5; // Reference to attributes  
    uint32 color\_id \= 6;          // Reference to color definition  
    uint32 original\_layer\_id \= 7; // ID from source EDA tool  
    // ... other metadata fields  
}

message LayerDirectory {  
    repeated LayerRecord layers \= 1;  
    // ... other directory-level metadata  
}

enum LayerType {  
    SIGNAL \= 0;  
    POWER\_GROUND \= 1;  
    MIXED \= 2;  
    SOLDER\_MASK \= 3;  
    SOLDER\_PASTE \= 4;  
    SILK\_SCREEN \= 5;  
    DRILL \= 6;  
    ROUT \= 7;  
    DOCUMENT \= 8;  
    COMPONENT \= 9;  
    // ... other types  
}

enum LayerContext {  
    BOARD \= 0;  
    PANEL \= 1;  
}

