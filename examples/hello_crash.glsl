#include <file.glsl>
#include <parallel.glsl>

void main() {
    if (ThreadId == 0) {
        println("Hello from crash!");
        println(`We are running on ${ThreadLocalCount * ThreadGroupCount} threads across ${ThreadGroupCount} thread groups. Let me introduce the first four thread groups.`);
    }
    globalBarrier();
    if (ThreadGroupId < 4 && ThreadLocalId % 16 == 0) {
        println(`Thread ${ThreadId} from thread group ${ThreadGroupId}[${ThreadLocalId}] checking in.`);
    }
    globalBarrier();
    if (ThreadId == 0) {
        println("What's your name?");
        string name = awaitIO(readLine(stdin, malloc(256)));
        println(`Hello ${name}!`);
    }
}
