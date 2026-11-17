---
title: "Ownership in C3 Without unique_ptr"
date: 2026-11-17
authors:
  - Manuel Linares
slug: c3-ownership
---

A question from Discord: *"Coming from C++, I used `std::move` and `std::unique_ptr` to control ownership. How should I think about ownership in C3?"*

C3 has no destructors, move semantics, deleted copy constructors or borrow checker. Instead of making each pointer own an object, you group allocations by **lifetime** and free each group at once. You keep data in **value containers** instead of linking separately allocated objects with pointers. Contracts and debug tooling catch mistakes that the compiler doesn't.

## 1. Pass an `Allocator`: arenas and `@pool()`

Instead of objects owning child objects, functions take an `Allocator` and allocate into a shared lifetime. When that lifetime ends, everything is freed at once. There's no per-object `free` and no cleanup chain for partial failures.

```c3
import std;

struct Node { int x; Node* next; }

fn Node* build_list(Allocator alloc)
{
    Node* a = alloc::new(alloc, Node, { .x = 1 });
    a.next = alloc::new(alloc, Node, { .x = 2 });
    return a;
}

fn void main()
{
    // Option A: heap-backed arena for a subsystem or task
    DynamicArenaAllocator arena;
    arena.init(mem, 4096);
    defer arena.free();
    Node* list = build_list(&arena);

    // Option B: thread-local temp arena for scratch work
    @pool()
    {
        Node* tmp = build_list(tmem);
    }; // all tmem allocations made in the pool are released here
}
```

## 2. Store values in flat containers, not pointer graphs

Structs are values. Keep them contiguous in a `List{T}` or slice instead of allocating each element separately. One `free()` releases them all.

```c3
List{Node} nodes;
nodes.init(mem);
defer nodes.free();

nodes.push({ .x = 1 });
sz first = 0;           // refer to elements by index
nodes.push({ .x = 2 });
io::printn(nodes[first].x);
```

Use indices, not `Node*`, to refer to elements. A `push` can reallocate the list's storage, which leaves earlier element pointers dangling.

## 3. `defer` / `defer catch` for handles and standalone buffers

For files, sockets or single buffers that must be closed or freed individually, put the cleanup right after the acquisition:

- `defer f.close();` always runs on scope exit, including on a `!` rethrow.
- `defer catch mem::free(buf);` runs only if the function exits with a fault, so `buf` stays alive when it's returned normally.

```c3
fn char[]? read_header(String path)
{
    File f = file::open(path, "rb")!;
    defer f.close();

    char[] buf = mem::new_array(char, 64);
    defer catch mem::free(buf);

    f.read(buf)!;
    return buf;
}
```

## 4. Document boundaries, verify in debug and test builds

The compiler won't stop you from copying a pointer, so document ownership and let the tooling check it.

**[Parameter contracts](https://c3-lang.org/language-common/contracts/#parameter-annotations)**

- `@param [in]` / `@param [out]`: the compiler rejects direct writes to `in` parameters and direct reads from `out` parameters.
- `@param [&in]` (also `[&out]`, `[&inout]`): adds a runtime non-null check in safe mode.
- `@param [own]` / `@param [drop]`: document that a function takes ownership of, or invalidates, an argument. The compiler doesn't check these.

**Naming conventions**

- `new_*` takes an `Allocator`.
- `t*` / `temp_*` allocates with `tmem`.
- `free` / `destroy` / `close` release resources.

**Tooling**

- `@test` functions fail on leaks by default and print a backtrace for each leaked allocation (`--test-noleak` turns this off).
- `mem::@assert_leak() { ... };` checks for leaks in any scope.
- `-D VMEM_TEMP`: in safe or debug builds, use of `tmem` memory after its `@pool` ends crashes immediately instead of reading garbage.
- `--sanitize=address`: AddressSanitizer catches use-after-free, double-free and leaks.

## Summary

| C++ | C3 |
|---|---|
| `unique_ptr` per object | Allocator / arena per lifetime |
| `vector<unique_ptr<T>>` | `List{T}` + indices |
| RAII destructor | `defer` / `defer catch` |
| Deleted copy constructor | `[own]` / `[drop]` contracts + ASan / leak checks |

See also: [How C3 Manages Memory Without Leaks, GC, or Borrow Checkers](https://c3-lang.org/blog/how-c3-manages-memory-without-leaks%2C-gc%2C-or-borrow-checkers/).
