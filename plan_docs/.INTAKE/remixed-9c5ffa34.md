# Performer Identifier - Complete Code Reference

This document contains all code files for the Performer Identifier application. Copy each file to the appropriate location in your project structure.

---

## Table of Contents

### Project Files
1. [PerformerIdentifier.Core.csproj](#1-performeridentifiercorecsproj)
2. [PerformerIdentifier.Windows.csproj](#2-performeridentifierwindowscsproj)
3. [PerformerIdentifier.App.csproj](#3-performeridentifierappcsproj)

### Core Library (PerformerIdentifier.Core)
4. [Interfaces/IFaceDetectionService.cs](#4-interfacesifacedetectionservicecs)
5. [Services/FaceDetectionServiceBase.cs](#5-servicesfacedetectionservicebasecs)
6. [Services/VideoProcessorService.cs](#6-servicesvideoprocessorservicecs)
7. [Services/ImageSharpImplementation.cs](#7-servicesimagessharpimplementationcs)
8. [Data/PerformerDatabase.cs](#8-dataperformerdatabasecs)

### Windows Implementation (PerformerIdentifier.Windows)
9. [Services/WindowsImageData.cs](#9-serviceswindowsimagedatacs)
10. [Services/WindowsVideoFrameExtractor.cs](#10-serviceswindowsvideoframeextractorcs)

### Application Layer (PerformerIdentifier.App)
11. [App.xaml.cs](#11-appxamlcs)
12. [MainWindow.xaml](#12-mainwindowxaml)
13. [MainWindow.xaml.cs](#13-mainwindowxamlcs)
14. [ViewModels/MainViewModel.cs](#14-viewmodelsmainviewmodelcs)

---

## Project Files

### 1. PerformerIdentifier.Core.csproj

**Location:** `PerformerIdentifier.Core/PerformerIdentifier.Core.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.ML.OnnxRuntime" Version="1.17.1" />
    <PackageReference Include="SixLabors.ImageSharp" Version="3.1.3" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.0.2" />
    <PackageReference Include="CommunityToolkit.Mvvm" Version="8.2.2" />
  </ItemGroup>
</Project>
```

---

### 2. PerformerIdentifier.Windows.csproj

**Location:** `PerformerIdentifier.Windows/PerformerIdentifier.Windows.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0-windows10.0.22621.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.19041.0</TargetPlatformMinVersion>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\PerformerIdentifier.Core\PerformerIdentifier.Core.csproj" />
    <PackageReference Include="Microsoft.ML.OnnxRuntime.DirectML" Version="1.17.1" />
    <PackageReference Include="Microsoft.Windows.SDK.Contracts" Version="10.0.22621.3233" />
  </ItemGroup>
</Project>
```

---

### 3. PerformerIdentifier.App.csproj

**Location:** `PerformerIdentifier.App/PerformerIdentifier.App.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows10.0.22621.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.19041.0</TargetPlatformMinVersion>
    <RootNamespace>PerformerIdentifier.App</RootNamespace>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <Platforms>x64;ARM64</Platforms>
    <RuntimeIdentifiers>win-x64;win-arm64</RuntimeIdentifiers>
    <UseWinUI>true</UseWinUI>
    <EnableMsixTooling>true</EnableMsixTooling>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\PerformerIdentifier.Core\PerformerIdentifier.Core.csproj" />
    <ProjectReference Include="..\PerformerIdentifier.Windows\PerformerIdentifier.Windows.csproj" />
    <PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.240802000" />
    <PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.22621.3233" />
    <PackageReference Include="CommunityToolkit.WinUI.UI.Controls" Version="7.1.2" />
  </ItemGroup>

  <ItemGroup>
    <Manifest Include="$(ApplicationManifest)" />
  </ItemGroup>
</Project>
```

---

## Core Library Files

### 4. Interfaces/IFaceDetectionService.cs

**Location:** `PerformerIdentifier.Core/Interfaces/IFaceDetectionService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace PerformerIdentifier.Core.Interfaces;

/// <summary>
/// Platform-agnostic image data container
/// </summary>
public interface IImageData
{
    int Width { get; }
    int Height { get; }
    byte[] GetPixelData(); // BGRA8 format
    void Dispose();
}

/// <summary>
/// Face detection result
/// </summary>
public record FaceDetection(
    float X, 
    float Y, 
    float Width, 
    float Height, 
    float Confidence);

/// <summary>
/// Face embedding with associated detection
/// </summary>
public record FaceEmbedding(
    float[] Vector, 
    FaceDetection Detection);

/// <summary>
/// Core face detection and recognition interface
/// Platform implementations provide concrete implementations
/// </summary>
public interface IFaceDetectionService : IDisposable
{
    /// <summary>
    /// Initialize models from file paths
    /// </summary>
    Task InitializeAsync(string detectionModelPath, string recognitionModelPath);

    /// <summary>
    /// Detect faces in an image
    /// </summary>
    Task<List<FaceDetection>> DetectFacesAsync(IImageData image);

    /// <summary>
    /// Extract embeddings for detected faces
    /// </summary>
    Task<FaceEmbedding[]> ExtractEmbeddingsAsync(IImageData image, List<FaceDetection> faces);

    /// <summary>
    /// Calculate similarity between two embeddings (0-1, higher is more similar)
    /// </summary>
    float CalculateSimilarity(float[] embedding1, float[] embedding2);

    /// <summary>
    /// Get embedding dimension (e.g., 512 for ArcFace)
    /// </summary>
    int EmbeddingDimension { get; }
}

/// <summary>
/// Video frame extraction interface
/// Platform implementations handle video decoding
/// </summary>
public interface IVideoFrameExtractor : IDisposable
{
    /// <summary>
    /// Get video metadata
    /// </summary>
    Task<VideoMetadata> GetMetadataAsync(string videoPath);

    /// <summary>
    /// Extract a specific frame by number
    /// </summary>
    Task<IImageData?> ExtractFrameAsync(string videoPath, int frameNumber);

    /// <summary>
    /// Extract frame at specific timestamp
    /// </summary>
    Task<IImageData?> ExtractFrameAtTimeAsync(string videoPath, TimeSpan timestamp);

    /// <summary>
    /// Get thumbnail (first frame or middle frame)
    /// </summary>
    Task<IImageData?> GetThumbnailAsync(string videoPath);
}

/// <summary>
/// Video metadata
/// </summary>
public record VideoMetadata(
    double FrameRate,
    int TotalFrames,
    TimeSpan Duration,
    int Width,
    int Height);

/// <summary>
/// Model configuration
/// </summary>
public record ModelConfiguration(
    string DetectionModelPath,
    string RecognitionModelPath,
    int DetectionInputSize = 640,
    int RecognitionInputSize = 112,
    float DetectionThreshold = 0.5f);

/// <summary>
/// Hardware acceleration options
/// </summary>
public enum AccelerationType
{
    CPU,
    GPU,
    NPU,
    Auto // Let the implementation decide
}

/// <summary>
/// Inference session configuration
/// </summary>
public record InferenceConfiguration(
    AccelerationType Acceleration = AccelerationType.Auto,
    int BatchSize = 1,
    bool EnableOptimizations = true);
```

---

### 5. Services/FaceDetectionServiceBase.cs

**Location:** `PerformerIdentifier.Core/Services/FaceDetectionServiceBase.cs`

```csharp
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using PerformerIdentifier.Core.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics.Tensors;
using System.Threading.Tasks;

namespace PerformerIdentifier.Core.Services;

/// <summary>
/// Base implementation of face detection using ONNX Runtime
/// Platform-agnostic, works with any IImageData implementation
/// </summary>
public abstract class FaceDetectionServiceBase : IFaceDetectionService
{
    protected InferenceSession? DetectionSession;
    protected InferenceSession? RecognitionSession;
    protected ModelConfiguration? Config;
    
    public int EmbeddingDimension { get; protected set; } = 512; // Default for ArcFace

    public async Task InitializeAsync(string detectionModelPath, string recognitionModelPath)
    {
        Config = new ModelConfiguration(detectionModelPath, recognitionModelPath);
        
        var sessionOptions = CreateSessionOptions();
        
        await Task.Run(() =>
        {
            DetectionSession = new InferenceSession(detectionModelPath, sessionOptions);
            RecognitionSession = new InferenceSession(recognitionModelPath, sessionOptions);
            
            // Infer embedding dimension from model output
            var recognitionOutput = RecognitionSession.OutputMetadata.First();
            EmbeddingDimension = recognitionOutput.Value.Dimensions.Last();
        });
    }

    /// <summary>
    /// Platform implementations override this to configure hardware acceleration
    /// </summary>
    protected abstract SessionOptions CreateSessionOptions();

    public async Task<List<FaceDetection>> DetectFacesAsync(IImageData image)
    {
        if (DetectionSession == null || Config == null)
            throw new InvalidOperationException("Service not initialized");

        var inputTensor = await PreprocessForDetectionAsync(image, Config.DetectionInputSize);
        
        var inputs = new List<NamedOnnxValue>
        {
            NamedOnnxValue.CreateFromTensor(DetectionSession.InputNames[0], inputTensor)
        };

        using var results = DetectionSession.Run(inputs);
        return ParseDetectionResults(results, Config.DetectionThreshold);
    }

    public async Task<FaceEmbedding[]> ExtractEmbeddingsAsync(
        IImageData image, 
        List<FaceDetection> faces)
    {
        if (RecognitionSession == null || Config == null)
            throw new InvalidOperationException("Service not initialized");

        var embeddings = new List<FaceEmbedding>();

        foreach (var face in faces)
        {
            var faceCrop = CropFace(image, face);
            var inputTensor = await PreprocessForRecognitionAsync(faceCrop, Config.RecognitionInputSize);
            
            var inputs = new List<NamedOnnxValue>
            {
                NamedOnnxValue.CreateFromTensor(RecognitionSession.InputNames[0], inputTensor)
            };

            using var results = RecognitionSession.Run(inputs);
            var embeddingTensor = results.First().AsTensor<float>();
            
            var embedding = embeddingTensor.ToArray();
            NormalizeEmbedding(embedding);
            
            embeddings.Add(new FaceEmbedding(embedding, face));
            
            faceCrop.Dispose();
        }

        return embeddings.ToArray();
    }

    public float CalculateSimilarity(float[] embedding1, float[] embedding2)
    {
        return TensorPrimitives.CosineSimilarity(embedding1, embedding2);
    }

    /// <summary>
    /// Preprocess image for detection model
    /// Input: BGRA8 pixel data
    /// Output: [1, 3, H, W] tensor normalized to [0, 1]
    /// </summary>
    protected async Task<DenseTensor<float>> PreprocessForDetectionAsync(IImageData image, int targetSize)
    {
        var tensor = new DenseTensor<float>(new[] { 1, 3, targetSize, targetSize });
        var pixelData = image.GetPixelData();
        
        await Task.Run(() =>
        {
            float scaleX = (float)image.Width / targetSize;
            float scaleY = (float)image.Height / targetSize;

            for (int y = 0; y < targetSize; y++)
            {
                for (int x = 0; x < targetSize; x++)
                {
                    int srcX = Math.Min((int)(x * scaleX), image.Width - 1);
                    int srcY = Math.Min((int)(y * scaleY), image.Height - 1);
                    int srcIdx = (srcY * image.Width + srcX) * 4; // BGRA format

                    // Convert BGRA -> RGB and normalize to [0, 1]
                    tensor[0, 0, y, x] = pixelData[srcIdx + 2] / 255f; // R
                    tensor[0, 1, y, x] = pixelData[srcIdx + 1] / 255f; // G
                    tensor[0, 2, y, x] = pixelData[srcIdx] / 255f;     // B
                }
            }
        });

        return tensor;
    }

    /// <summary>
    /// Preprocess image for recognition model
    /// Input: BGRA8 pixel data
    /// Output: [1, 3, H, W] tensor normalized to [-1, 1]
    /// </summary>
    protected async Task<DenseTensor<float>> PreprocessForRecognitionAsync(IImageData image, int targetSize)
    {
        var tensor = new DenseTensor<float>(new[] { 1, 3, targetSize, targetSize });
        var pixelData = image.GetPixelData();
        
        await Task.Run(() =>
        {
            float scaleX = (float)image.Width / targetSize;
            float scaleY = (float)image.Height / targetSize;

            for (int y = 0; y < targetSize; y++)
            {
                for (int x = 0; x < targetSize; x++)
                {
                    int srcX = Math.Min((int)(x * scaleX), image.Width - 1);
                    int srcY = Math.Min((int)(y * scaleY), image.Height - 1);
                    int srcIdx = (srcY * image.Width + srcX) * 4;

                    // Convert BGRA -> RGB and normalize to [-1, 1]
                    tensor[0, 0, y, x] = (pixelData[srcIdx + 2] / 127.5f) - 1f;
                    tensor[0, 1, y, x] = (pixelData[srcIdx + 1] / 127.5f) - 1f;
                    tensor[0, 2, y, x] = (pixelData[srcIdx] / 127.5f) - 1f;
                }
            }
        });

        return tensor;
    }

    /// <summary>
    /// Parse detection model output
    /// Expected format: [1, N, 6] where 6 = [x, y, w, h, conf, class]
    /// </summary>
    protected virtual List<FaceDetection> ParseDetectionResults(
        IDisposableReadOnlyCollection<DisposableNamedOnnxValue> results,
        float threshold)
    {
        var detections = new List<FaceDetection>();
        var outputTensor = results.First().AsTensor<float>();
        
        // Handle different output formats
        if (outputTensor.Dimensions.Length == 3)
        {
            // Format: [batch, num_detections, attributes]
            int numDetections = outputTensor.Dimensions[1];
            
            for (int i = 0; i < numDetections; i++)
            {
                float confidence = outputTensor[0, i, 4];
                
                if (confidence > threshold)
                {
                    detections.Add(new FaceDetection(
                        X: outputTensor[0, i, 0],
                        Y: outputTensor[0, i, 1],
                        Width: outputTensor[0, i, 2],
                        Height: outputTensor[0, i, 3],
                        Confidence: confidence
                    ));
                }
            }
        }

        return detections;
    }

    /// <summary>
    /// Crop face region from image with padding
    /// </summary>
    protected IImageData CropFace(IImageData source, FaceDetection face)
    {
        const float padding = 0.2f;
        
        int x = Math.Max(0, (int)(face.X - face.Width * padding));
        int y = Math.Max(0, (int)(face.Y - face.Height * padding));
        int w = Math.Min(source.Width - x, (int)(face.Width * (1 + 2 * padding)));
        int h = Math.Min(source.Height - y, (int)(face.Height * (1 + 2 * padding)));
        
        return CropImageImplementation(source, x, y, w, h);
    }

    /// <summary>
    /// Platform implementations provide image cropping
    /// </summary>
    protected abstract IImageData CropImageImplementation(
        IImageData source, 
        int x, int y, 
        int width, int height);

    protected void NormalizeEmbedding(float[] embedding)
    {
        float norm = MathF.Sqrt(embedding.Sum(x => x * x));
        if (norm > 0)
        {
            for (int i = 0; i < embedding.Length; i++)
                embedding[i] /= norm;
        }
    }

    public virtual void Dispose()
    {
        DetectionSession?.Dispose();
        RecognitionSession?.Dispose();
    }
}
```

---

### 6. Services/VideoProcessorService.cs

**Location:** `PerformerIdentifier.Core/Services/VideoProcessorService.cs`

```csharp
using PerformerIdentifier.Core.Data;
using PerformerIdentifier.Core.Interfaces;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace PerformerIdentifier.Core.Services;

public record VideoProcessingProgress(
    int CurrentFrame,
    int TotalFrames,
    int FacesDetected,
    TimeSpan Elapsed,
    string Status);

public record PerformerMatch(
    int PerformerId,
    string PerformerName,
    float Confidence,
    int FrameNumber,
    TimeSpan Timestamp);

/// <summary>
/// Platform-agnostic video processing service
/// Uses dependency injection for platform-specific implementations
/// </summary>
public class VideoProcessorService
{
    private readonly IFaceDetectionService _faceService;
    private readonly IVideoFrameExtractor _frameExtractor;
    private readonly PerformerRepository _repository;

    public VideoProcessorService(
        IFaceDetectionService faceService,
        IVideoFrameExtractor frameExtractor,
        PerformerRepository repository)
    {
        _context.VideoProcessingResults.Add(result);
        await _context.SaveChangesAsync();

        return result;
    }

    public async Task<List<VideoProcessingResult>> GetVideoHistoryAsync()
    {
        return await _context.VideoProcessingResults
            .Include(v => v.DetectedPerformers)
            .ThenInclude(d => d.Performer)
            .OrderByDescending(v => v.ProcessedAt)
            .ToListAsync();
    }

    public async Task<bool> DeletePerformerAsync(int performerId)
    {
        var performer = await _context.Performers.FindAsync(performerId);
        if (performer == null) return false;

        _context.Performers.Remove(performer);
        await _context.SaveChangesAsync();
        return true;
    }

    private static byte[] EmbeddingToBytes(float[] embedding)
    {
        var bytes = new byte[embedding.Length * sizeof(float)];
        Buffer.BlockCopy(embedding, 0, bytes, 0, bytes.Length);
        return bytes;
    }

    private static float[] BytesToEmbedding(byte[] bytes)
    {
        var embedding = new float[bytes.Length / sizeof(float)];
        Buffer.BlockCopy(bytes, 0, embedding, 0, bytes.Length);
        return embedding;
    }

    private static float CosineSimilarity(float[] a, float[] b)
    {
        float dot = 0, normA = 0, normB = 0;
        
        for (int i = 0; i < a.Length; i++)
        {
            dot += a[i] * b[i];
            normA += a[i] * a[i];
            normB += b[i] * b[i];
        }

        return dot / (MathF.Sqrt(normA) * MathF.Sqrt(normB));
    }
}
```

---

## Windows Implementation Files

### 9. Services/WindowsImageData.cs

**Location:** `PerformerIdentifier.Windows/Services/WindowsImageData.cs`

```csharp
using PerformerIdentifier.Core.Interfaces;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;
using System;

namespace PerformerIdentifier.Windows.Services;

/// <summary>
/// Windows implementation using SoftwareBitmap
/// </summary>
public class WindowsImageData : IImageData
{
    private readonly SoftwareBitmap _bitmap;
    private byte[]? _cachedPixelData;

    public WindowsImageData(SoftwareBitmap bitmap)
    {
        // Ensure BGRA8 format
        if (bitmap.BitmapPixelFormat != BitmapPixelFormat.Bgra8)
        {
            _bitmap = SoftwareBitmap.Convert(bitmap, BitmapPixelFormat.Bgra8, BitmapAlphaMode.Premultiplied);
        }
        else
        {
            _bitmap = bitmap;
        }
    }

    public int Width => _bitmap.PixelWidth;
    public int Height => _bitmap.PixelHeight;

    public byte[] GetPixelData()
    {
        if (_cachedPixelData != null)
            return _cachedPixelData;

        var buffer = new byte[Width * Height * 4];
        _bitmap.CopyToBuffer(buffer.AsBuffer());
        _cachedPixelData = buffer;
        return buffer;
    }

    public SoftwareBitmap GetSoftwareBitmap() => _bitmap;

    public void Dispose()
    {
        _bitmap?.Dispose();
        _cachedPixelData = null;
    }
}

/// <summary>
/// Windows-specific face detection service using DirectML
/// </summary>
public class WindowsFaceDetectionService : Core.Services.FaceDetectionServiceBase
{
    protected override Microsoft.ML.OnnxRuntime.SessionOptions CreateSessionOptions()
    {
        var options = new Microsoft.ML.OnnxRuntime.SessionOptions();
        
        try
        {
            // Try DirectML (GPU acceleration on Windows)
            options.AppendExecutionProvider_DML(0);
            options.GraphOptimizationLevel = Microsoft.ML.OnnxRuntime.GraphOptimizationLevel.ORT_ENABLE_ALL;
        }
        catch
        {
            // Fall back to CPU if DirectML not available
            options.GraphOptimizationLevel = Microsoft.ML.OnnxRuntime.GraphOptimizationLevel.ORT_ENABLE_ALL;
        }

        return options;
    }

    protected override IImageData CropImageImplementation(
        IImageData source, 
        int x, int y, 
        int width, int height)
    {
        if (source is not WindowsImageData winImage)
            throw new ArgumentException("Expected WindowsImageData", nameof(source));

        var srcBitmap = winImage.GetSoftwareBitmap();
        
        // Create cropped bitmap
        var cropped = new SoftwareBitmap(
            BitmapPixelFormat.Bgra8,
            width, height,
            BitmapAlphaMode.Premultiplied);

        // Copy pixel data
        var srcData = source.GetPixelData();
        var dstData = new byte[width * height * 4];

        for (int row = 0; row < height; row++)
        {
            int srcOffset = ((y + row) * source.Width + x) * 4;
            int dstOffset = row * width * 4;
            
            if (srcOffset + width * 4 <= srcData.Length)
            {
                Array.Copy(srcData, srcOffset, dstData, dstOffset, width * 4);
            }
        }

        cropped.CopyFromBuffer(dstData.AsBuffer());
        return new WindowsImageData(cropped);
    }
}
```

---

### 10. Services/WindowsVideoFrameExtractor.cs

**Location:** `PerformerIdentifier.Windows/Services/WindowsVideoFrameExtractor.cs`

```csharp
using PerformerIdentifier.Core.Interfaces;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Windows.Graphics.Imaging;
using Windows.Storage;
using Windows.Storage.Streams;

namespace PerformerIdentifier.Windows.Services;

/// <summary>
/// Windows implementation using FFmpeg for video processing
/// </summary>
public class WindowsVideoFrameExtractor : IVideoFrameExtractor
{
    private readonly string _ffmpegPath;
    private readonly string _ffprobePath;

    public WindowsVideoFrameExtractor(string? ffmpegPath = null, string? ffprobePath = null)
    {
        _ffmpegPath = ffmpegPath ?? "ffmpeg.exe";
        _ffprobePath = ffprobePath ?? "ffprobe.exe";
    }

    public async Task<VideoMetadata> GetMetadataAsync(string videoPath)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = _ffprobePath,
            Arguments = $"-v error -select_streams v:0 -show_entries stream=r_frame_rate,nb_frames,duration,width,height -of csv=p=0 \"{videoPath}\"",
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(startInfo);
        if (process == null)
            throw new InvalidOperationException("Failed to start ffprobe");

        var output = await process.StandardOutput.ReadToEndAsync();
        await process.WaitForExitAsync();

        // Parse: fps,frames,duration,width,height
        var parts = output.Trim().Split(',');
        
        var fpsStr = parts[0].Split('/');
        double fps = double.Parse(fpsStr[0]) / double.Parse(fpsStr[1]);
        int totalFrames = int.Parse(parts[1]);
        double durationSec = double.Parse(parts[2]);
        int width = int.Parse(parts[3]);
        int height = int.Parse(parts[4]);

        return new VideoMetadata(
            FrameRate: fps,
            TotalFrames: totalFrames,
            Duration: TimeSpan.FromSeconds(durationSec),
            Width: width,
            Height: height);
    }

    public async Task<IImageData?> ExtractFrameAsync(string videoPath, int frameNumber)
    {
        var metadata = await GetMetadataAsync(videoPath);
        double timestamp = frameNumber / metadata.FrameRate;
        return await ExtractFrameAtTimeAsync(videoPath, TimeSpan.FromSeconds(timestamp));
    }

    public async Task<IImageData?> ExtractFrameAtTimeAsync(string videoPath, TimeSpan timestamp)
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"frame_{Guid.NewGuid()}.png");

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = _ffmpegPath,
                Arguments = $"-ss {timestamp.TotalSeconds:F3} -i \"{videoPath}\" -frames:v 1 -f image2 \"{tempFile}\"",
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            if (process == null) return null;

            await process.WaitForExitAsync();

            if (!File.Exists(tempFile)) return null;

            // Load into SoftwareBitmap
            var file = await StorageFile.GetFileFromPathAsync(tempFile);
            using var stream = await file.OpenAsync(FileAccessMode.Read);
            var decoder = await BitmapDecoder.CreateAsync(stream);
            var bitmap = await decoder.GetSoftwareBitmapAsync(
                BitmapPixelFormat.Bgra8,
                BitmapAlphaMode.Premultiplied);

            return new WindowsImageData(bitmap);
        }
        catch
        {
            return null;
        }
        finally
        {
            try
            {
                if (File.Exists(tempFile))
                    File.Delete(tempFile);
            }
            catch { }
        }
    }

    public async Task<IImageData?> GetThumbnailAsync(string videoPath)
    {
        // Extract frame at 10% into video for better thumbnail
        var metadata = await GetMetadataAsync(videoPath);
        var timestamp = TimeSpan.FromSeconds(metadata.Duration.TotalSeconds * 0.1);
        return await ExtractFrameAtTimeAsync(videoPath, timestamp);
    }

    public void Dispose()
    {
        // No resources to dispose
    }
}
```

---

## Application Layer Files

### 11. App.xaml.cs

**Location:** `PerformerIdentifier.App/App.xaml.cs`

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml;
using PerformerIdentifier.Core.Data;
using PerformerIdentifier.Core.Interfaces;
using PerformerIdentifier.Core.Services;
using PerformerIdentifier.Windows.Services;
using PerformerIdentifier.App.ViewModels;
using System;

namespace PerformerIdentifier.App;

public partial class App : Application
{
    public IServiceProvider Services { get; }
    public new static App Current => (App)Application.Current;

    public App()
    {
        var services = new ServiceCollection();
        
        // Register Core Services
        services.AddSingleton<IFaceDetectionService, WindowsFaceDetectionService>();
        services.AddSingleton<IVideoFrameExtractor, WindowsVideoFrameExtractor>();
        services.AddSingleton<VideoProcessorService>();
        
        // Register Database
        services.AddDbContext<PerformerDbContext>();
        services.AddSingleton<PerformerRepository>();
        
        // Register ViewModels
        services.AddTransient<MainViewModel>();
        
        Services = services.BuildServiceProvider();
        
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        m_window = new MainWindow();
        m_window.Activate();
    }

    private Window? m_window;
}
```

---

### 12. MainWindow.xaml

**Location:** `PerformerIdentifier.App/MainWindow.xaml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<Window
    x:Class="PerformerIdentifier.App.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d"
    Title="Performer Identifier"
    MinWidth="1200"
    MinHeight="800">

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top Menu Bar -->
        <CommandBar Grid.Row="0" DefaultLabelPosition="Right">
            <AppBarButton Icon="OpenFile" Label="Open Video" Click="OpenVideoButton_Click"/>
            <AppBarButton Icon="Add" Label="Add Performer" Click="AddPerformerButton_Click"/>
            <AppBarSeparator/>
            <AppBarButton Icon="Play" Label="Process Video" Click="ProcessVideoButton_Click" 
                          x:Name="ProcessButton"
                          IsEnabled="False"/>
        </CommandBar>

        <!-- Main Content Area -->
        <Grid Grid.Row="1" Padding="20">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="20"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Video Player Section -->
            <Grid Grid.Column="0">
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Video Player with Overlay -->
                <Border Grid.Row="0" 
                        Background="#1A1A1A" 
                        CornerRadius="8"
                        BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                        BorderThickness="1">
                    <Grid>
                        <!-- Video Player -->
                        <MediaPlayerElement x:Name="VideoPlayer"
                                          AreTransportControlsEnabled="True"
                                          AutoPlay="False"
                                          Stretch="Uniform"/>

                        <!-- Face Detection Overlay Canvas -->
                        <Canvas x:Name="FaceOverlayCanvas"
                                IsHitTestVisible="False"/>
                    </Grid>
                </Border>

                <!-- Video Info -->
                <StackPanel Grid.Row="1" Margin="0,10,0,0">
                    <TextBlock x:Name="VideoInfoText" 
                               Text="No video loaded" 
                               Style="{StaticResource CaptionTextBlockStyle}"/>
                </StackPanel>
            </Grid>

            <!-- Right Panel - Results -->
            <Grid Grid.Column="2">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Results Header -->
                <TextBlock Grid.Row="0" 
                           Text="Detected Performers" 
                           Style="{StaticResource SubtitleTextBlockStyle}"
                           Margin="0,0,0,10"/>

                <!-- Results List -->
                <ListView Grid.Row="1"
                          x:Name="ResultsListView"
                          SelectionMode="Single">
                    <ListView.ItemTemplate>
                        <DataTemplate>
                            <Grid Padding="10">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBlock Grid.Row="0" 
                                           Text="{Binding PerformerName}"
                                           Style="{StaticResource BodyStrongTextBlockStyle}"/>
                                
                                <StackPanel Grid.Row="1" 
                                            Orientation="Horizontal"
                                            Spacing="10">
                                    <TextBlock Text="{Binding Appearances, StringFormat='{}Appearances: {0}'}"
                                               Style="{StaticResource CaptionTextBlockStyle}"/>
                                    <TextBlock Text="{Binding AvgConfidence, StringFormat='{}Confidence: {0:P0}'}"
                                               Style="{StaticResource CaptionTextBlockStyle}"/>
                                </StackPanel>
                            </Grid>
                        </DataTemplate>
                    </ListView.ItemTemplate>
                </ListView>
            </Grid>
        </Grid>

        <!-- Status Bar -->
        <Grid Grid.Row="2" 
              Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
              Padding="20,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <TextBlock x:Name="StatusText" 
                       Grid.Column="0"
                       Text="Ready" 
                       VerticalAlignment="Center"/>

            <ProgressBar x:Name="ProcessingProgress"
                         Grid.Column="1"
                         Width="200"
                         Height="4"
                         Visibility="Collapsed"/>
        </Grid>
    </Grid>
</Window>
```

---

### 13. MainWindow.xaml.cs

**Location:** `PerformerIdentifier.App/MainWindow.xaml.cs`

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PerformerIdentifier.App.ViewModels;
using Windows.Storage.Pickers;
using System;
using System.Linq;

namespace PerformerIdentifier.App;

public sealed partial class MainWindow : Window
{
    private MainViewModel ViewModel { get; }

    public MainWindow()
    {
        this.InitializeComponent();
        
        ViewModel = App.Current.Services.GetRequiredService<MainViewModel>();
        
        // Subscribe to ViewModel property changes
        ViewModel.PropertyChanged += ViewModel_PropertyChanged;
    }

    private void ViewModel_PropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            switch (e.PropertyName)
            {
                case nameof(MainViewModel.CurrentVideoPath):
                    ProcessButton.IsEnabled = !string.IsNullOrEmpty(ViewModel.CurrentVideoPath);
                    VideoInfoText.Text = ViewModel.CurrentVideoPath ?? "No video loaded";
                    break;

                case nameof(MainViewModel.StatusMessage):
                    StatusText.Text = ViewModel.StatusMessage;
                    break;

                case nameof(MainViewModel.IsProcessing):
                    ProcessingProgress.Visibility = ViewModel.IsProcessing 
                        ? Visibility.Visible 
                        : Visibility.Collapsed;
                    ProcessButton.IsEnabled = !ViewModel.IsProcessing && !string.IsNullOrEmpty(ViewModel.CurrentVideoPath);
                    break;

                case nameof(MainViewModel.ProcessingProgress):
                    ProcessingProgress.Value = ViewModel.ProcessingProgress;
                    break;

                case nameof(MainViewModel.DetectedPerformers):
                    ResultsListView.ItemsSource = ViewModel.DetectedPerformers;
                    break;
            }
        });
    }

    private async void OpenVideoButton_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        
        // Initialize with window handle
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);
        
        picker.FileTypeFilter.Add(".mp4");
        picker.FileTypeFilter.Add(".avi");
        picker.FileTypeFilter.Add(".mkv");
        picker.FileTypeFilter.Add(".mov");
        
        var file = await picker.PickSingleFileAsync();
        if (file != null)
        {
            await ViewModel.LoadVideoAsync(file.Path);
            
            // Load video into player
            var stream = await file.OpenAsync(Windows.Storage.FileAccessMode.Read);
            VideoPlayer.Source = Windows.Media.Core.MediaSource.CreateFromStream(stream, file.ContentType);
        }
    }

    private async void AddPerformerButton_Click(object sender, RoutedEventArgs e)
    {
        // TODO: Show Add Performer dialog
        var dialog = new ContentDialog
        {
            Title = "Add Performer",
            Content = "This feature will be implemented to add performers to the database.",
            CloseButtonText = "OK",
            XamlRoot = this.Content.XamlRoot
        };
        
        await dialog.ShowAsync();
    }

    private async void ProcessVideoButton_Click(object sender, RoutedEventArgs e)
    {
        await ViewModel.ProcessVideoAsync();
    }
}
```

---

### 14. ViewModels/MainViewModel.cs

**Location:** `PerformerIdentifier.App/ViewModels/MainViewModel.cs`

```csharp
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using PerformerIdentifier.Core.Data;
using PerformerIdentifier.Core.Interfaces;
using PerformerIdentifier.Core.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;

namespace PerformerIdentifier.App.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly VideoProcessorService _videoProcessor;
    private readonly PerformerRepository _repository;
    private readonly IFaceDetectionService _faceService;

    [ObservableProperty]
    private string? _currentVideoPath;

    [ObservableProperty]
    private bool _isProcessing;

    [ObservableProperty]
    private double _processingProgress;

    [ObservableProperty]
    private string _statusMessage = "Ready";

    [ObservableProperty]
    private ObservableCollection<PerformerMatchSummary> _detectedPerformers = new();

    public MainViewModel(
        VideoProcessorService videoProcessor,
        PerformerRepository repository,
        IFaceDetectionService faceService)
    {
        _videoProcessor = videoProcessor;
        _repository = repository;
        _faceService = faceService;
        
        // Initialize models
        _ = InitializeModelsAsync();
    }

    private async Task InitializeModelsAsync()
    {
        try
        {
            StatusMessage = "Initializing ML models...";
            
            // TODO: Get model paths from configuration
            var detectionModelPath = "Models/detection.onnx";
            var recognitionModelPath = "Models/recognition.onnx";
            
            await _faceService.InitializeAsync(detectionModelPath, recognitionModelPath);
            
            StatusMessage = "Ready";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Failed to initialize models: {ex.Message}";
        }
    }

    public async Task LoadVideoAsync(string videoPath)
    {
        CurrentVideoPath = videoPath;
        StatusMessage = $"Loaded: {System.IO.Path.GetFileName(videoPath)}";
    }

    [RelayCommand]
    public async Task ProcessVideoAsync()
    {
        if (string.IsNullOrEmpty(CurrentVideoPath))
            return;

        IsProcessing = true;
        ProcessingProgress = 0;
        DetectedPerformers.Clear();
        StatusMessage = "Processing video...";

        var progress = new Progress<VideoProcessingProgress>(p =>
        {
            ProcessingProgress = (double)p.CurrentFrame / p.TotalFrames * 100;
            StatusMessage = $"{p.Status} - {p.FacesDetected} faces detected";
        });

        try
        {
            var matches = await _videoProcessor.ProcessVideoAsync(
                CurrentVideoPath!,
                frameIntervalSeconds: 1,
                progress: progress
            );

            // Group by performer and summarize
            var summaries = matches
                .GroupBy(m => new { m.PerformerId, m.PerformerName })
                .Select(g => new PerformerMatchSummary
                {
                    PerformerId = g.Key.PerformerId,
                    PerformerName = g.Key.PerformerName,
                    Appearances = g.Count(),
                    AvgConfidence = g.Average(m => m.Confidence),
                    FirstAppearance = g.Min(m => m.Timestamp),
                    LastAppearance = g.Max(m => m.Timestamp)
                })
                .OrderByDescending(s => s.Appearances)
                .ToList();

            DetectedPerformers = new ObservableCollection<PerformerMatchSummary>(summaries);

            StatusMessage = $"Processing complete! Found {DetectedPerformers.Count} performers";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
        }
        finally
        {
            IsProcessing = false;
            ProcessingProgress = 0;
        }
    }
}

public class PerformerMatchSummary
{
    public int PerformerId { get; set; }
    public string PerformerName { get; set; } = string.Empty;
    public int Appearances { get; set; }
    public float AvgConfidence { get; set; }
    public TimeSpan FirstAppearance { get; set; }
    public TimeSpan LastAppearance { get; set; }
}
```

---

## Quick Reference: File Locations

```
PerformerIdentifier/
│
├── PerformerIdentifier.sln
│
├── PerformerIdentifier.Core/
│   ├── PerformerIdentifier.Core.csproj
│   ├── Interfaces/
│   │   └── IFaceDetectionService.cs
│   ├── Services/
│   │   ├── FaceDetectionServiceBase.cs
│   │   ├── VideoProcessorService.cs
│   │   └── ImageSharpImplementation.cs
│   └── Data/
│       └── PerformerDatabase.cs
│
├── PerformerIdentifier.Windows/
│   ├── PerformerIdentifier.Windows.csproj
│   └── Services/
│       ├── WindowsImageData.cs
│       └── WindowsVideoFrameExtractor.cs
│
├── PerformerIdentifier.App/
│   ├── PerformerIdentifier.App.csproj
│   ├── App.xaml
│   ├── App.xaml.cs
│   ├── MainWindow.xaml
│   ├── MainWindow.xaml.cs
│   └── ViewModels/
│       └── MainViewModel.cs
│
└── Models/                    (Create this folder)
    ├── detection.onnx         (Download separately)
    └── recognition.onnx       (Download separately)
```

---

## Next Steps

1. **Create the solution structure** as shown above
2. **Copy each code file** to its respective location
3. **Download ONNX models** following the Model Acquisition Guide
4. **Install FFmpeg** and add to PATH
5. **Build the solution**: `dotnet build`
6. **Run the application**: `dotnet run --project PerformerIdentifier.App`

All code is ready to use - just follow the Development Plan for implementation order!faceService = faceService;
        _frameExtractor = frameExtractor;
        _repository = repository;
    }

    public async Task<List<PerformerMatch>> ProcessVideoAsync(
        string videoPath,
        int frameIntervalSeconds = 1,
        IProgress<VideoProcessingProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var sw = Stopwatch.StartNew();
        var matches = new List<PerformerMatch>();
        var performerStats = new Dictionary<int, PerformerStats>();

        // Get video metadata
        var metadata = await _frameExtractor.GetMetadataAsync(videoPath);
        
        // Calculate frame sampling interval
        int frameInterval = Math.Max(1, (int)(metadata.FrameRate * frameIntervalSeconds));
        int totalFramesToProcess = metadata.TotalFrames / frameInterval;
        int framesProcessed = 0;
        int facesDetected = 0;

        for (int frameNum = 0; frameNum < metadata.TotalFrames; frameNum += frameInterval)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var frame = await _frameExtractor.ExtractFrameAsync(videoPath, frameNum);
            if (frame == null) continue;

            try
            {
                // Detect faces
                var faces = await _faceService.DetectFacesAsync(frame);
                facesDetected += faces.Count;

                if (faces.Count > 0)
                {
                    // Extract embeddings
                    var embeddings = await _faceService.ExtractEmbeddingsAsync(frame, faces);

                    // Match against database
                    foreach (var embedding in embeddings)
                    {
                        var (performer, similarity) = await _repository.FindMostSimilarPerformerAsync(
                            embedding.Vector,
                            threshold: 0.6f);

                        if (performer != null)
                        {
                            var timestamp = TimeSpan.FromSeconds(frameNum / metadata.FrameRate);
                            
                            matches.Add(new PerformerMatch(
                                PerformerId: performer.Id,
                                PerformerName: performer.Name,
                                Confidence: similarity,
                                FrameNumber: frameNum,
                                Timestamp: timestamp
                            ));

                            // Update stats
                            if (!performerStats.ContainsKey(performer.Id))
                            {
                                performerStats[performer.Id] = new PerformerStats
                                {
                                    FirstFrame = frameNum,
                                    LastFrame = frameNum,
                                    Confidences = new List<float>()
                                };
                            }

                            var stats = performerStats[performer.Id];
                            stats.LastFrame = frameNum;
                            stats.Count++;
                            stats.Confidences.Add(similarity);
                        }
                    }
                }

                framesProcessed++;

                // Report progress
                progress?.Report(new VideoProcessingProgress(
                    CurrentFrame: framesProcessed,
                    TotalFrames: totalFramesToProcess,
                    FacesDetected: facesDetected,
                    Elapsed: sw.Elapsed,
                    Status: $"Processing frame {frameNum}/{metadata.TotalFrames}"
                ));
            }
            finally
            {
                frame.Dispose();
            }
        }

        // Save results to database
        var detectionDict = performerStats.ToDictionary(
            kvp => kvp.Key,
            kvp => (
                kvp.Value.FirstFrame,
                kvp.Value.LastFrame,
                kvp.Value.Count,
                kvp.Value.Confidences.Average()
            )
        );

        await _repository.SaveVideoResultAsync(
            videoPath,
            framesProcessed,
            facesDetected,
            detectionDict);

        return matches;
    }

    public async Task<IImageData?> GetVideoThumbnailAsync(string videoPath)
    {
        return await _frameExtractor.GetThumbnailAsync(videoPath);
    }

    private class PerformerStats
    {
        public int FirstFrame { get; set; }
        public int LastFrame { get; set; }
        public int Count { get; set; }
        public List<float> Confidences { get; set; } = new();
    }
}
```

---

### 7. Services/ImageSharpImplementation.cs

**Location:** `PerformerIdentifier.Core/Services/ImageSharpImplementation.cs`

```csharp
using PerformerIdentifier.Core.Interfaces;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Microsoft.ML.OnnxRuntime;

namespace PerformerIdentifier.Core.Services;

/// <summary>
/// Cross-platform image data using ImageSharp
/// Works with Avalonia, WPF, Console, Web, etc.
/// </summary>
public class ImageSharpImageData : IImageData
{
    private readonly Image<Bgra32> _image;
    private byte[]? _cachedPixelData;

    public ImageSharpImageData(Image<Bgra32> image)
    {
        _image = image;
    }

    public ImageSharpImageData(string imagePath)
    {
        _image = Image.Load<Bgra32>(imagePath);
    }

    public int Width => _image.Width;
    public int Height => _image.Height;

    public byte[] GetPixelData()
    {
        if (_cachedPixelData != null)
            return _cachedPixelData;

        var buffer = new byte[Width * Height * 4];
        _image.CopyPixelDataTo(buffer);
        _cachedPixelData = buffer;
        return buffer;
    }

    public Image<Bgra32> GetImage() => _image;

    public void Dispose()
    {
        _image?.Dispose();
        _cachedPixelData = null;
    }
}

/// <summary>
/// Cross-platform face detection service
/// Uses CPU by default, can be GPU-accelerated on supported platforms
/// </summary>
public class CrossPlatformFaceDetectionService : FaceDetectionServiceBase
{
    private readonly AccelerationType _accelerationType;

    public CrossPlatformFaceDetectionService(AccelerationType accelerationType = AccelerationType.CPU)
    {
        _accelerationType = accelerationType;
    }

    protected override SessionOptions CreateSessionOptions()
    {
        var options = new SessionOptions
        {
            GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL
        };

        // CPU is default and works everywhere
        // GPU acceleration available on Windows/Linux with appropriate providers

        return options;
    }

    protected override IImageData CropImageImplementation(
        IImageData source,
        int x, int y,
        int width, int height)
    {
        if (source is not ImageSharpImageData imgSharpData)
            throw new ArgumentException("Expected ImageSharpImageData", nameof(source));

        var srcImage = imgSharpData.GetImage();
        
        var cropped = srcImage.Clone(ctx => ctx.Crop(new Rectangle(x, y, width, height)));
        return new ImageSharpImageData(cropped);
    }
}

/// <summary>
/// Cross-platform video frame extractor using FFmpeg
/// Works on Windows, Linux, macOS
/// </summary>
public class CrossPlatformVideoFrameExtractor : IVideoFrameExtractor
{
    private readonly string _ffmpegPath;
    private readonly string _ffprobePath;

    public CrossPlatformVideoFrameExtractor(string? ffmpegPath = null, string? ffprobePath = null)
    {
        // Auto-detect platform
        _ffmpegPath = ffmpegPath ?? (OperatingSystem.IsWindows() ? "ffmpeg.exe" : "ffmpeg");
        _ffprobePath = ffprobePath ?? (OperatingSystem.IsWindows() ? "ffprobe.exe" : "ffprobe");
    }

    public async Task<VideoMetadata> GetMetadataAsync(string videoPath)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = _ffprobePath,
            Arguments = $"-v error -select_streams v:0 -show_entries stream=r_frame_rate,nb_frames,duration,width,height -of csv=p=0 \"{videoPath}\"",
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(startInfo);
        if (process == null)
            throw new InvalidOperationException("Failed to start ffprobe. Ensure FFmpeg is installed.");

        var output = await process.StandardOutput.ReadToEndAsync();
        await process.WaitForExitAsync();

        var parts = output.Trim().Split(',');
        
        var fpsStr = parts[0].Split('/');
        double fps = double.Parse(fpsStr[0]) / double.Parse(fpsStr[1]);
        int totalFrames = int.Parse(parts[1]);
        double durationSec = double.Parse(parts[2]);
        int width = int.Parse(parts[3]);
        int height = int.Parse(parts[4]);

        return new VideoMetadata(fps, totalFrames, TimeSpan.FromSeconds(durationSec), width, height);
    }

    public async Task<IImageData?> ExtractFrameAsync(string videoPath, int frameNumber)
    {
        var metadata = await GetMetadataAsync(videoPath);
        double timestamp = frameNumber / metadata.FrameRate;
        return await ExtractFrameAtTimeAsync(videoPath, TimeSpan.FromSeconds(timestamp));
    }

    public async Task<IImageData?> ExtractFrameAtTimeAsync(string videoPath, TimeSpan timestamp)
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"frame_{Guid.NewGuid()}.png");

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = _ffmpegPath,
                Arguments = $"-ss {timestamp.TotalSeconds:F3} -i \"{videoPath}\" -frames:v 1 -f image2 \"{tempFile}\"",
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            if (process == null) return null;

            await process.WaitForExitAsync();

            if (!File.Exists(tempFile)) return null;

            var image = await Image.LoadAsync<Bgra32>(tempFile);
            return