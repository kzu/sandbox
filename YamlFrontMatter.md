---
exec-mode: default
platform: WPF
uti: com.xamarin.workbook
packages:
  - id: YamlDotNet
    version: 3.8.0
  - id: Microsoft.Bcl,
    version: 1.1.10
  - id: Microsoft.Bcl.Build
    version: 1.0.21
  - id: Microsoft.Net.Http
    version: 2.2.29
---
```json
{"exec-mode":"default","platform":"WPF","uti":"com.xamarin.workbook","packages":[{"id":"YamlDotNet","version":"3.8.0"},{"id":"Microsoft.Bcl","version":"1.1.10"}x,{"id":"Microsoft.Bcl.Build","version":"1.0.21"},{"id":"Microsoft.Net.Http","version":"2.2.29"}]}
```

```csharp
#r "YamlDotNet"
#r "System.Net.Http.Extensions"
#r "System.Net.Http.Primitives"
```

# YAML vs JSON for Workbook Metadata

Workbooks are great because you can just upload them to GitHub and have people collaborate
even just using a brower: update, send pull requests, merge, comment on lines, etc.

Anyone who has used Jekyll (meaning anyone who has used GitHub Pages) is likely familiar
with Front-Matter, which basically is markup at the begining of the document which is
distinct from the rest because it uses a totally different markup:

    ---
    layout: post
    title: Blogging Like a Hacker
    ---

The front-matter isn't just more readable while editing the text file, it's also 
rendered nicely by GitHub itself, as can be seen here https://github.com/kzu/sandbox/blob/master/YamlFrontMatter.md 

The way to read it is pretty straightforward with the help of the `YamlDotNet` nuget
package, which is actively developed and pretty stable.

First the imports:

```csharp
using System.IO;
using System.Text;
using System.Net.Http;
using YamlDotNet.RepresentationModel;
using YamlDotNet.Serialization;
```

I've uploaded a sample workbook with YAML front-matter equivalent to this doc's json at:

```csharp
const string docUrl = "https://raw.githubusercontent.com/kzu/sandbox/master/YamlFrontMatter.md";
```

The following helper code just reads the string between the start and end `---` in that doc, 
in a way that avoids reading the whole doc just to get the front-matter: 

```csharp
async Task<string> ReadFrontMatter() {
  using (var response = await new HttpClient ().GetAsync (docUrl)) {
    using (var stream = await response.Content.ReadAsStreamAsync ()) {
      using (var reader = new StreamReader (stream)) {
        var line = await reader.ReadLineAsync();
        // Grab just the front-matter
        if (line == "---") {
          var frontMatter = new StringBuilder();
          while ((line = await reader.ReadLineAsync ()) != "---") {
            frontMatter.AppendLine (line);
          }

          return frontMatter.ToString();
        }
      }
    }
  }
  
  return null;
}
```

We can now easily read the YAML into various forms.

```csharp
var frontMatter = await ReadFrontMatter();
```

We can load to a JSON Linq-like in-memory model:
```csharp
var stream = new YamlStream();
stream.Load (new StringReader (frontMatter));
```

Render what we read into the structured in-memory model 
as a string:
```csharp
var writer = new StringWriter();
stream.Save (writer, false);
var yaml = writer.ToString();
```

Or we can load the yaml into a dynamic object just like 
Json.NET:

```csharp
var obj = new Deserializer().Deserialize(new StringReader(frontMatter));
```


And that object can be trivially be converted back to JSON for feeding 
into whatever current code processes it as JSON:

```csharp
writer = new StringWriter();
new Serializer (SerializationOptions.JsonCompatible).Serialize (writer, obj);
var json = writer.ToString();
```

We can load the Workbooks built-in JSON metadata to compare:

```csharp
async static Task<string> ReadJsonMetadata ()
{
  using (var response = await new HttpClient ().GetAsync (docUrl)) {
    using (var stream = await response.Content.ReadAsStreamAsync ()) {
      using (var reader = new StreamReader (stream)) {
        var line = await reader.ReadLineAsync();
        while (line != "```json") {
          line = await reader.ReadLineAsync ();
        }
        // Return the next line, which is the metadata
        return await reader.ReadLineAsync ();
      }
    }
  }
}
```

```csharp
var original = await ReadJsonMetadata();
```
Compared to:
```csharp
var fromYaml = writer.ToString(); 
```
