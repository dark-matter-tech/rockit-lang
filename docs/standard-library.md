# Standard Library

22 modules. Import with `import rockit.<domain>.<module>`.

## Core

### rockit.core.collections
```rockit
import rockit.core.collections

listMap(list, { x -> x * 2 })
listFilter(list, { x -> x > 0 })
listFold(list, 0, { acc, x -> acc + x })
listSort(list, { a, b -> a - b })
listZip(list1, list2)
listFlatten(nestedList)
```

### rockit.core.math
```rockit
import rockit.core.math

gcd(12, 8)          // 4
lcm(3, 4)           // 12
clamp(15, 0, 10)    // 10
lerp(0.0, 10.0, 0.5) // 5.0
PI                   // 3.14159...
```

### rockit.core.strings
```rockit
import rockit.core.strings

pad("hi", 10, " ")        // "hi        "
repeat("ab", 3)            // "ababab"
join(items, ", ")           // "a, b, c"
split("a,b,c", ",")        // ["a", "b", "c"]
replace("hello", "l", "r") // "herro"
```

### rockit.core.result
```rockit
import rockit.core.result

val r = Success(42)
resultMap(r, { v -> v * 2 })    // Success(84)
resultOrElse(r, 0)              // 42
```

### rockit.core.uuid
```rockit
import rockit.core.uuid

val id = uuid4()   // "550e8400-e29b-41d4-a716-446655440000"
```

## Encoding

### rockit.encoding.json
```rockit
import rockit.encoding.json

val obj = jsonParse("{\"name\": \"Rockit\"}")
val name = jsonGetString(jsonObjectGet(obj, "name"))

val data = jsonObject()
jsonObjectPut(data, "version", jsonNumber(1))
println(jsonStringify(data))
```

### rockit.encoding.base64
```rockit
import rockit.encoding.base64

val encoded = base64Encode("Hello")     // "SGVsbG8="
val decoded = base64Decode("SGVsbG8=")  // "Hello"
```

### rockit.encoding.xml
```rockit
import rockit.encoding.xml

val doc = xmlParse("<root><item>hello</item></root>")
val xml = xmlStringify(doc)
```

## File System

### rockit.filesystem.file
```rockit
import rockit.filesystem.file

val content = readFile("data.txt")
writeFile("output.txt", "hello")
val exists = exists("config.json")
```

### rockit.filesystem.path
```rockit
import rockit.filesystem.path

pathJoin("src", "main.rok")     // "src/main.rok"
pathDir("/usr/bin/rockit")      // "/usr/bin"
pathBase("/usr/bin/rockit")     // "rockit"
pathExt("main.rok")            // ".rok"
```

## Networking

### rockit.networking.http
```rockit
import rockit.networking.http

val response = httpGet("https://api.example.com/data")
httpPost("https://api.example.com/submit", body)
```

### rockit.networking.url
```rockit
import rockit.networking.url

val parsed = urlParse("https://example.com/path?q=hello")
val encoded = urlEncode("hello world")   // "hello%20world"
```

### rockit.networking.websocket
```rockit
import rockit.networking.websocket

val ws = wsConnect("wss://echo.websocket.org")
wsSend(ws, "hello")
val msg = wsRecv(ws)
wsClose(ws)
```

## Time

### rockit.time.datetime
```rockit
import rockit.time.datetime

val ts = now()
val date = dateFromEpoch(ts)
println(formatDate(date, "YYYY-MM-DD"))
val dow = dayOfWeek(date)
```

## Testing

### rockit.testing.probe
```rockit
import rockit.testing.probe

fun testAddition() {
    assertEquals(2 + 2, 4)
    assertNotEquals(1, 2)
    assertTrue(10 > 5)
    assertFalse(1 > 2)
    assertStringContains("hello world", "world")
    assertBetween(5, 1, 10)
}
```

Run tests:
```bash
rockit test my_tests.rok
```

## Builtin Functions

These are available without imports:

| Function | Description |
|----------|-------------|
| `println(value)` | Print with newline |
| `print(value)` | Print without newline |
| `readLine()` | Read line from stdin |
| `toString(value)` | Convert to string |
| `toInt(value)` | Convert to integer |
| `stringLength(s)` | String length |
| `charAt(s, i)` | Character at index |
| `substring(s, start, end)` | Substring |
| `stringIndexOf(s, needle)` | Find index (-1 if not found) |
| `startsWith(s, prefix)` | Prefix check |
| `endsWith(s, suffix)` | Suffix check |
| `stringTrim(s)` | Trim whitespace |
| `listCreate()` | New empty list |
| `listAppend(list, value)` | Append to list |
| `listGet(list, index)` | Get by index |
| `listSet(list, index, value)` | Set by index |
| `listSize(list)` | List length |
| `mapCreate()` | New empty map |
| `mapPut(map, key, value)` | Set key-value |
| `mapGet(map, key)` | Get by key (null if missing) |
| `mapKeys(map)` | Get all keys |
| `fileRead(path)` | Read file contents |
| `fileExists(path)` | Check file exists |
| `processArgs()` | Command line args |
| `getEnv(name)` | Environment variable |
| `systemExec(cmd)` | Run shell command |
