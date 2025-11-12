using Azure.Identity;
using Azure.Storage.Blobs;
using FileUploadApp.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

// Configure Azure Blob Storage with Managed Identity
builder.Services.AddSingleton(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    var storageAccountName = configuration["AzureStorage:AccountName"];
    var blobServiceUri = new Uri($"https://{storageAccountName}.blob.core.windows.net");
    
    // Use DefaultAzureCredential which supports Managed Identity
    var credential = new DefaultAzureCredential();
    return new BlobServiceClient(blobServiceUri, credential);
});

builder.Services.AddScoped<IFileStorageService, FileStorageService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
