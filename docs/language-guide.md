# Language Guide

Rockit has Kotlin-like syntax with additions for UI, concurrency, and systems programming.

## Variables

```rockit
val name = "Rockit"          // Immutable
var count = 0                // Mutable
val x: Int = 42              // Explicit type
val pi: Float = 3.14159
val flag: Bool = true
```

## Types

| Type | Description |
|------|-------------|
| `Int` | 64-bit signed integer |
| `Int8`, `Int16`, `Int32`, `Int64` | Narrow signed integers |
| `UInt8`, `UInt16`, `UInt32`, `UInt64` | Unsigned integers |
| `Float` | 64-bit floating point |
| `Bool` | `true` or `false` |
| `String` | UTF-8 string |
| `Unit` | No value (like void) |
| `Any` | Any type |

## Null Safety

```rockit
val name: String = "hello"    // Non-null
val maybe: String? = null     // Nullable

// Safe call
val len = maybe?.length

// Elvis operator
val safe = maybe ?: "default"

// Force unwrap (crashes if null)
val forced = maybe!!
```

## Functions

```rockit
fun greet(name: String): String {
    return "Hello, $name!"
}

// Expression body
fun add(a: Int, b: Int): Int = a + b

// Default parameters
fun connect(host: String, port: Int = 8080): Unit {
    println("Connecting to $host:$port")
}

// Suspend function (async)
suspend fun fetchData(): String {
    val result = await httpGet("https://example.com")
    return result
}
```

## String Interpolation

```rockit
val name = "World"
println("Hello, $name!")
println("2 + 2 = ${2 + 2}")
```

## Control Flow

### If / Else

```rockit
if (x > 0) {
    println("positive")
} else if (x < 0) {
    println("negative")
} else {
    println("zero")
}

// If as expression
val abs = if (x >= 0) { x } else { 0 - x }
```

### When (Pattern Matching)

```rockit
when (x) {
    1 -> println("one")
    2 -> println("two")
    in 3..10 -> println("three to ten")
    else -> println("other")
}

// Type matching
when (shape) {
    is Circle -> println("circle")
    is Rectangle -> println("rectangle")
}
```

### Loops

```rockit
// For loop
for (i in 0..10) {
    println(i)
}

// For over list
for (item in items) {
    println(item)
}

// While
while (count < 100) {
    count = count + 1
}

// Do-while
do {
    val line = readLine()
} while (stringLength(line) > 0)
```

## Classes

```rockit
class Animal {
    var name: String = ""
    var age: Int = 0

    fun speak(): String {
        return "..."
    }
}

val dog = Animal()
dog.name = "Rex"
println(dog.name)
```

### Constructors

```rockit
class Point(x: Int, y: Int) {
    fun distanceTo(other: Point): Float {
        val dx = this.x - other.x
        val dy = this.y - other.y
        return rockit_math_sqrt(toFloat(dx * dx + dy * dy))
    }
}

val p = Point(3, 4)
```

### Inheritance

```rockit
open class Shape {
    open fun area(): Float { return 0.0 }
}

class Circle(radius: Float) : Shape {
    override fun area(): Float {
        return 3.14159 * radius * radius
    }
}
```

### Data Classes

```rockit
data class User(name: String, age: Int)

val user = User("Alice", 30)
println(user.toString())    // User(name=Alice, age=30)
```

### Sealed Classes

```rockit
sealed class Result {
    data class Success(value: Int) : Result
    data class Error(message: String) : Result
}

fun handle(r: Result) {
    when (r) {
        is Result.Success -> println("ok")
        is Result.Error -> println("fail")
    }
    // Compiler enforces all cases are covered
}
```

## Enum Classes

```rockit
enum class Direction {
    North, South, East, West
}

// With associated values
enum class Option {
    Some(value: Int),
    None
}

val x = Option.Some(42)
when (x) {
    is Option.Some(val v) -> {
        println("value: " + toString(v))
    }
    is Option.None -> println("empty")
}
```

## Interfaces

```rockit
interface Drawable {
    fun draw(): Unit

    // Default implementation
    fun description(): String {
        return "a drawable object"
    }
}

class Button : Drawable {
    override fun draw() {
        println("drawing button")
    }
}
```

## Generics

```rockit
class Box<T>(value: T) {
    fun get(): T { return value }
}

val intBox = Box<Int>(42)
val strBox = Box<String>("hello")
```

## Lambdas

```rockit
val double = { x: Int -> x * 2 }
println(double(21))    // 42

// Trailing lambda
items.forEach { item ->
    println(item)
}
```

## Concurrency

```rockit
// Suspend functions
suspend fun fetchUser(id: Int): User {
    return await httpGet("/users/$id")
}

// Concurrent blocks
concurrent {
    val user = fetchUser(1)
    val posts = fetchPosts(1)
}
// Both run concurrently, joined here

// Actors (thread-safe)
actor Counter {
    var count: Int = 0
    fun increment() { count = count + 1 }
    fun getCount(): Int { return count }
}
```

## Error Handling

```rockit
fun divide(a: Int, b: Int): Int {
    if (b == 0) {
        throw "division by zero"
    }
    return a / b
}

try {
    val result = divide(10, 0)
} catch (e) {
    println("Error: " + toString(e))
}
```

## Collections

```rockit
// Lists
val list = listCreate()
listAppend(list, 1)
listAppend(list, 2)
println(listGet(list, 0))     // 1
println(listSize(list))       // 2

// Maps (string keys)
val m = mapCreate()
mapPut(m, "name", "Rockit")
println(mapGet(m, "name"))    // Rockit
```

## Imports

```rockit
import rockit.encoding.json
import rockit.networking.http
import rockit.core.collections

fun main() {
    val data = jsonParse("{\"key\": \"value\"}")
    val response = httpGet("https://api.example.com/data")
    val sorted = listSort(myList, { a, b -> a - b })
}
```

## View Declarations (UI)

```rockit
view HelloScreen(name: String) {
    Column {
        Text("Hello, $name!")
        Button("Click me") {
            println("clicked!")
        }
    }
}
```

## Freestanding Mode

For systems programming and safety-critical code:

```rockit
// Compile with: rockit build-native app.rok --no-runtime

extern fun malloc(size: Int): Int
extern fun free(ptr: Int): Unit
extern fun printf(fmt: Ptr<Int>, value: Int): Int

fun main() {
    unsafe {
        val buf = alloc(1024)
        storeByte(buf, 0, 72)    // 'H'
        storeByte(buf, 1, 105)   // 'i'
        storeByte(buf, 2, 0)     // null terminator
        printf(cstr("%s\n"), bitcast<Int>(buf))
        free(bitcast<Int>(buf))
    }
}
```
