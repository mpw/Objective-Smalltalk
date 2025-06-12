import java.util.stream.IntStream;
import java.util.Iterator;

public class StreamSieve {

    public static void main(String[] args) {
        IntStream primes = sieve(IntStream.iterate(2, i -> i + 1));

        // Print the first 10 primes
        primes.limit(10).forEach(System.out::println);
    }

    public static IntStream sieve(IntStream numbers) {
        class State {
            IntStream current = numbers;
            Iterator<Integer> it = current.iterator();
        }

        State state = new State();

        return IntStream.generate(new java.util.function.IntSupplier() {
            @Override
            public int getAsInt() {
                int prime = state.it.next();
                state.current = state.current.filter(n -> n % prime != 0);
                state.it = state.current.iterator();
                return prime;
            }
        });
    }
}