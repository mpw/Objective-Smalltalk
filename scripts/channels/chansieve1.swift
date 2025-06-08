import Foundation

// Generate an AsyncStream of Ints starting from 2
func generate() -> AsyncStream<Int> {
    return AsyncStream { continuation in
        Task {
            var i = 2
            while true {
                continuation.yield(i)
                i += 1
            }
        }
    }
}

// Filter values from input stream and yield only those not divisible by `prime`
func filter(input: AsyncStream<Int>, prime: Int) -> AsyncStream<Int> {
    return AsyncStream { continuation in
        Task {
            for await number in input {
                if number % prime != 0 {
                    continuation.yield(number)
                }
            }
        }
    }
}

// Run the sieve
func runSieve(limit: Int) async {
    var stream = generate()

    for _ in 0..<limit {
        guard let prime = await stream.first(where: { _ in true }) else {
            break
        }

        print(prime)
        stream = filter(input: stream, prime: prime)
    }
}

await runSieve(limit: 100)
