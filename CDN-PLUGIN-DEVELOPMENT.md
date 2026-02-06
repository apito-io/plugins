# CDN Plugin Development Guide

This guide explains how to develop CDN/storage plugins for the Apito Engine, using the `hc-apito-cdn-plugin` (Cloudflare R2) implementation as a reference. You can adapt this pattern to work with any cloud storage provider like AWS S3, Google Cloud Storage, Cloudinary, or custom storage solutions.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [What We Implemented](#what-we-implemented)
3. [Storage Provider Integration Patterns](#storage-provider-integration-patterns)
4. [Creating Your Own CDN Plugin](#creating-your-own-cdn-plugin)
5. [Storage Provider Examples](#storage-provider-examples)
6. [Frontend Integration](#frontend-integration)
7. [Testing and Deployment](#testing-and-deployment)
8. [Best Practices](#best-practices)

## 🏗️ Architecture Overview

### Plugin Structure
```
hc-[provider]-cdn-plugin/
├── main.go                    # Plugin implementation
├── go.mod                     # Go dependencies
├── go.sum                     # Dependency checksums
├── ui/                        # Frontend React component
│   ├── src/
│   │   ├── components/
│   │   │   └── MediaGallery.tsx
│   │   ├── graphql-client.ts  # GraphQL client setup
│   │   └── index.tsx          # Plugin registration
│   ├── package.json
│   └── dist/                  # Built UI assets
├── Makefile                   # Build automation
└── README.md                  # Plugin documentation
```

### Core Components

1. **Storage Client**: Handles interaction with your chosen storage provider
2. **GraphQL Resolvers**: Provides query and mutation endpoints
3. **REST API Handlers**: Supports multipart file uploads
4. **Frontend Components**: React-based UI for file management
5. **Plugin Registration**: Integration with Apito Engine

## 🚀 What We Implemented

### Backend Features

#### 1. Storage Client (R2Client)
```go
type R2Client struct {
    s3Client *s3.S3
    bucket   string
}

func NewR2Client() (*R2Client, error) {
    // Configure storage client
    sess, err := session.NewSession(&aws.Config{
        Region:           aws.String(region),
        Endpoint:         aws.String(endpoint),
        Credentials:      credentials.NewStaticCredentials(accessKey, secretKey, ""),
        S3ForcePathStyle: aws.Bool(true),
    })
    // ...
}
```

#### 2. Core Operations
- **List Files**: `ListPhotos()` - Retrieve all files with metadata
- **Upload Files**: `UploadPhoto()` - Store files with metadata and tags
- **Delete Files**: `DeletePhotos()` - Bulk delete with error handling

#### 3. GraphQL Schema
```graphql
type Photo {
  id: String!
  url: String!
  fileName: String!
  size: Int!
  contentType: String!
  createdAt: String!
  tags: [String!]
}

type Query {
  getPhotos(limit: Int, offset: Int, search: String): PhotosResponse!
}

type Mutation {
  deletePhotos(photoIds: [String!]!): DeletePhotosResponse!
}
```

#### 4. REST API Endpoints
- `POST /upload/photos` - Multipart file upload
- `GET /photos` - List files with pagination

#### 5. Multipart Upload Pattern (Following established conventions)
```go
// Extract file from structured args
if fileUploads, ok := args["file_uploads"].(map[string]interface{}); ok {
    if fileInfo, exists := fileUploads["photo"].(map[string]interface{}); exists {
        // Handle both []byte and base64 content
        // Extract filename, content_type, size
    }
}

// Extract form fields with body_ prefix
description := sdk.GetBodyParam(args, "body_description", "")
category := sdk.GetBodyParam(args, "body_category", "")
```

### Frontend Features

#### 1. GraphQL Integration with urql
```typescript
import { useQuery, useMutation } from 'urql';

// Queries and mutations
const [{ data, fetching, error }, refetchPhotos] = useQuery<{ getPhotos: PhotosResponse }>({
    query: GET_PHOTOS,
    variables: { limit: pageSize, offset: offset, search: searchTerm }
});

const [, deletePhotosMutation] = useMutation(DELETE_PHOTOS);
```

#### 2. Multipart Upload
```typescript
export const uploadPhoto = async (file: File, description: string, category: string, tags: string[]) => {
    const formData = new FormData();
    formData.append('photo', file);
    formData.append('description', description);
    formData.append('category', category);
    tags.forEach(tag => formData.append('tags[]', tag));
    
    const response = await fetch('/plugin/hc-[provider]-cdn-plugin/upload/photos', {
        method: 'POST',
        body: formData
    });
    
    return response.json();
};
```

#### 3. UI Components
- Photo grid with selection
- Upload modal with metadata fields
- Search and pagination
- Bulk operations (delete)
- Photo preview modal

## 🔌 Storage Provider Integration Patterns

### Pattern 1: S3-Compatible APIs (Cloudflare R2, DigitalOcean Spaces, MinIO)

Use AWS SDK with custom endpoint:

```go
sess, err := session.NewSession(&aws.Config{
    Region:           aws.String("auto"),
    Endpoint:         aws.String("https://your-endpoint.com"),
    Credentials:      credentials.NewStaticCredentials(accessKey, secretKey, ""),
    S3ForcePathStyle: aws.Bool(true), // Required for some providers
})
```

### Pattern 2: Native SDKs (Google Cloud, Azure)

Use provider-specific SDKs:

```go
// Google Cloud Storage example
import "cloud.google.com/go/storage"

client, err := storage.NewClient(ctx, option.WithCredentialsFile("service-account.json"))
bucket := client.Bucket("your-bucket-name")
```

### Pattern 3: REST API Integration (Cloudinary, ImageKit)

Use HTTP client for API calls:

```go
type CloudinaryClient struct {
    cloudName string
    apiKey    string
    apiSecret string
    baseURL   string
}

func (c *CloudinaryClient) UploadImage(file []byte, filename string) (*ImageResponse, error) {
    // Implementation using HTTP requests
}
```

## 🛠️ Creating Your Own CDN Plugin

### Step 1: Plugin Setup

1. **Create Plugin Directory**
```bash
mkdir hc-[provider]-cdn-plugin
cd hc-[provider]-cdn-plugin
```

2. **Initialize Go Module**
```bash
go mod init hc-[provider]-cdn-plugin
```

3. **Copy Base Structure**
Use this plugin as a template and modify the storage client implementation.

### Step 2: Implement Storage Client

Replace the `R2Client` with your provider's client:

```go
type [Provider]Client struct {
    client interface{}  // Your provider's client
    config Config
}

func New[Provider]Client(config Config) (*[Provider]Client, error) {
    // Initialize your provider's client
    // Configure authentication
    // Set up any required options
}

func (c *[Provider]Client) ListFiles(ctx context.Context) ([]File, error) {
    // Implementation for listing files
}

func (c *[Provider]Client) UploadFile(ctx context.Context, file []byte, metadata FileMetadata) (*File, error) {
    // Implementation for uploading files
}

func (c *[Provider]Client) DeleteFiles(ctx context.Context, fileIDs []string) error {
    // Implementation for deleting files
}
```

### Step 3: Update Dependencies

Add your storage provider's SDK to `go.mod`:

```go
require (
    github.com/apito-io/go-apito-plugin-sdk v0.1.6
    // Add your provider's SDK here
    // Examples:
    // cloud.google.com/go/storage v1.30.1        // Google Cloud Storage
    // github.com/Azure/azure-storage-blob-go v0.15.0  // Azure Blob Storage
    // github.com/cloudinary/cloudinary-go/v2 v2.7.0   // Cloudinary
)
```

### Step 4: Update Configuration

Modify the configuration variables for your provider:

```go
var (
    // Replace with your provider's configuration
    apiKey     = os.Getenv("PROVIDER_API_KEY")
    apiSecret  = os.Getenv("PROVIDER_API_SECRET")
    bucketName = os.Getenv("PROVIDER_BUCKET_NAME")
    region     = os.Getenv("PROVIDER_REGION")
)
```

### Step 5: Update Plugin Registration

```go
func main() {
    plugin := sdk.Init("hc-[provider]-cdn-plugin", "1.0.0", "apito-plugin-key")
    
    // Register the same GraphQL schema (works with any provider)
    // Register the same REST endpoints
    // Only the client implementation changes
    
    plugin.Serve()
}
```

## 📚 Storage Provider Examples

### AWS S3

```go
type S3Client struct {
    s3Client *s3.S3
    bucket   string
}

func NewS3Client() (*S3Client, error) {
    sess, err := session.NewSession(&aws.Config{
        Region: aws.String("us-east-1"),
        Credentials: credentials.NewStaticCredentials(
            os.Getenv("AWS_ACCESS_KEY_ID"),
            os.Getenv("AWS_SECRET_ACCESS_KEY"),
            "",
        ),
    })
    if err != nil {
        return nil, err
    }
    
    return &S3Client{
        s3Client: s3.New(sess),
        bucket:   os.Getenv("AWS_S3_BUCKET"),
    }, nil
}
```

### Google Cloud Storage

```go
import (
    "cloud.google.com/go/storage"
    "google.golang.org/api/option"
)

type GCSClient struct {
    client *storage.Client
    bucket string
}

func NewGCSClient(ctx context.Context) (*GCSClient, error) {
    client, err := storage.NewClient(ctx, 
        option.WithCredentialsFile(os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")))
    if err != nil {
        return nil, err
    }
    
    return &GCSClient{
        client: client,
        bucket: os.Getenv("GCS_BUCKET_NAME"),
    }, nil
}

func (g *GCSClient) UploadFile(ctx context.Context, file []byte, filename string) error {
    obj := g.client.Bucket(g.bucket).Object(filename)
    w := obj.NewWriter(ctx)
    defer w.Close()
    
    if _, err := w.Write(file); err != nil {
        return err
    }
    
    return nil
}
```

### Cloudinary

```go
import "github.com/cloudinary/cloudinary-go/v2"

type CloudinaryClient struct {
    cld *cloudinary.Cloudinary
}

func NewCloudinaryClient() (*CloudinaryClient, error) {
    cld, err := cloudinary.NewFromParams(
        os.Getenv("CLOUDINARY_CLOUD_NAME"),
        os.Getenv("CLOUDINARY_API_KEY"),
        os.Getenv("CLOUDINARY_API_SECRET"),
    )
    if err != nil {
        return nil, err
    }
    
    return &CloudinaryClient{cld: cld}, nil
}

func (c *CloudinaryClient) UploadFile(ctx context.Context, file []byte, filename string) (*cloudinary.UploadResult, error) {
    return c.cld.Upload.Upload(ctx, bytes.NewReader(file), uploader.UploadParams{
        PublicID: filename,
        Folder:   "uploads",
    })
}
```

### DigitalOcean Spaces

```go
// DigitalOcean Spaces uses S3-compatible API
func NewDOSpacesClient() (*S3Client, error) {
    sess, err := session.NewSession(&aws.Config{
        Region:           aws.String("nyc3"),
        Endpoint:         aws.String("https://nyc3.digitaloceanspaces.com"),
        Credentials:      credentials.NewStaticCredentials(accessKey, secretKey, ""),
        S3ForcePathStyle: aws.Bool(false),
    })
    // ... rest similar to S3
}
```

### Azure Blob Storage

```go
import "github.com/Azure/azure-storage-blob-go/azblob"

type AzureBlobClient struct {
    containerURL azblob.ContainerURL
}

func NewAzureBlobClient() (*AzureBlobClient, error) {
    accountName := os.Getenv("AZURE_STORAGE_ACCOUNT_NAME")
    accountKey := os.Getenv("AZURE_STORAGE_ACCOUNT_KEY")
    containerName := os.Getenv("AZURE_STORAGE_CONTAINER_NAME")
    
    credential, err := azblob.NewSharedKeyCredential(accountName, accountKey)
    if err != nil {
        return nil, err
    }
    
    pipeline := azblob.NewPipeline(credential, azblob.PipelineOptions{})
    URL, _ := url.Parse(fmt.Sprintf("https://%s.blob.core.windows.net/%s", accountName, containerName))
    containerURL := azblob.NewContainerURL(*URL, pipeline)
    
    return &AzureBlobClient{containerURL: containerURL}, nil
}
```

## 🎨 Frontend Integration

### Setting Up GraphQL Client

1. **Install Dependencies**
```bash
npm install urql graphql
```

2. **Create GraphQL Client**
```typescript
import { createClient, cacheExchange, fetchExchange } from 'urql';

export const graphqlClient = createClient({
    url: '/graphql',
    exchanges: [cacheExchange, fetchExchange],
});
```

3. **Define Queries and Mutations**
```typescript
export const GET_FILES = `
    query GetFiles($limit: Int, $offset: Int, $search: String) {
        getFiles(limit: $limit, offset: $offset, search: $search) {
            files { id url fileName size contentType createdAt tags }
            totalCount offset limit hasMore
        }
    }
`;

export const DELETE_FILES = `
    mutation DeleteFiles($fileIds: [String!]!) {
        deleteFiles(fileIds: $fileIds) {
            success message deletedIds count
        }
    }
`;
```

### Upload Function Template

```typescript
export const uploadFile = async (
    file: File, 
    description: string = '', 
    category: string = '', 
    tags: string[] = []
): Promise<any> => {
    const formData = new FormData();
    formData.append('file', file);  // Adjust field name as needed
    if (description) formData.append('description', description);
    if (category) formData.append('category', category);
    tags.forEach(tag => formData.append('tags[]', tag));

    const response = await fetch('/plugin/hc-[provider]-cdn-plugin/upload/files', {
        method: 'POST',
        headers: {
            ...(((window as any).ApitoPluginAPI?.getAuthToken?.() && {
                'Authorization': `Bearer ${(window as any).ApitoPluginAPI.getAuthToken()}`
            }) || {}),
        },
        body: formData,
    });

    if (!response.ok) {
        throw new Error(`Upload failed: ${response.statusText}`);
    }

    return response.json();
};
```

## 🧪 Testing and Deployment

### Local Development

1. **Build Plugin**
```bash
go build -o hc-[provider]-cdn-plugin main.go
```

2. **Build UI**
```bash
cd ui && npm install && npm run build
```

3. **Test Plugin Registration**
```bash
./hc-[provider]-cdn-plugin
```

### Integration Testing

1. **Test File Upload**
```bash
curl -X POST \
  http://localhost:8080/plugin/hc-[provider]-cdn-plugin/upload/files \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -F 'file=@test-image.jpg' \
  -F 'description=Test upload' \
  -F 'category=test'
```

2. **Test GraphQL Queries**
```graphql
query {
  getFiles(limit: 10, offset: 0) {
    files {
      id url fileName size contentType createdAt
    }
    totalCount hasMore
  }
}
```

### Deployment Checklist

- [ ] Environment variables configured
- [ ] Storage bucket/container created and accessible
- [ ] Plugin binary built for target architecture
- [ ] UI assets built and included
- [ ] Health checks implemented
- [ ] Error handling tested
- [ ] Documentation updated

## 🎯 Best Practices

### Security

1. **Environment Variables**: Never hardcode credentials
```go
var (
    apiKey     = os.Getenv("PROVIDER_API_KEY")
    apiSecret  = os.Getenv("PROVIDER_API_SECRET")
    bucketName = os.Getenv("PROVIDER_BUCKET_NAME")
)
```

2. **Input Validation**: Always validate file types and sizes
```go
func validateFile(filename string, size int64) error {
    if !isValidFileType(filename) {
        return errors.New("invalid file type")
    }
    if size > maxFileSize {
        return errors.New("file too large")
    }
    return nil
}
```

3. **Error Handling**: Use appropriate error codes
```go
if err != nil {
    return nil, sdk.InternalServerError("Storage operation failed")
}
```

### Performance

1. **Connection Pooling**: Reuse client connections
2. **Async Operations**: Use context for cancellation
3. **Batch Operations**: Support bulk delete/upload
4. **Caching**: Cache metadata when appropriate

### Maintainability

1. **Interface Design**: Abstract storage operations
```go
type StorageProvider interface {
    ListFiles(ctx context.Context) ([]File, error)
    UploadFile(ctx context.Context, file []byte, metadata FileMetadata) (*File, error)
    DeleteFiles(ctx context.Context, fileIDs []string) error
}
```

2. **Configuration**: Use structured config
```go
type Config struct {
    Provider    string
    Credentials ProviderCredentials
    Bucket      string
    Region      string
    Options     map[string]interface{}
}
```

3. **Logging**: Structured logging with context
```go
log.Printf("🚀 [hc-%s-plugin] %s: %s", provider, operation, details)
```

### Monitoring

1. **Health Checks**: Implement storage connectivity checks
2. **Metrics**: Track upload/download success rates
3. **Alerts**: Monitor storage quota and errors

## 🔗 Provider-Specific Resources

### Documentation Links
- **AWS S3**: https://docs.aws.amazon.com/s3/
- **Google Cloud Storage**: https://cloud.google.com/storage/docs
- **Azure Blob Storage**: https://docs.microsoft.com/en-us/azure/storage/blobs/
- **Cloudinary**: https://cloudinary.com/documentation
- **DigitalOcean Spaces**: https://docs.digitalocean.com/products/spaces/
- **Cloudflare R2**: https://developers.cloudflare.com/r2/

### SDK Repositories
- **AWS SDK for Go**: https://github.com/aws/aws-sdk-go
- **Google Cloud Go**: https://github.com/googleapis/google-cloud-go
- **Azure SDK for Go**: https://github.com/Azure/azure-sdk-for-go
- **Cloudinary Go**: https://github.com/cloudinary/cloudinary-go

---

## 🚀 Quick Start Template

Use this as a starting point for any new storage provider:

```bash
# 1. Clone this plugin as template
cp -r hc-apito-cdn-plugin hc-[provider]-cdn-plugin

# 2. Update module name
sed -i 's/hc-apito-cdn-plugin/hc-[provider]-cdn-plugin/g' go.mod

# 3. Replace storage client implementation in main.go
# 4. Update dependencies in go.mod
# 5. Configure environment variables
# 6. Test and deploy
```

This architecture provides a robust, scalable foundation for any CDN/storage plugin while maintaining consistency with the Apito Engine ecosystem. 