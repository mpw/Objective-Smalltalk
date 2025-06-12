import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

public class StreamIterator {

    public static void main(String[] args) {
        Iterator<Integer> primes = sieve();

        for (int i = 0; i < 1000; i++) {
            System.out.println(primes.next());
        }
    }

    public static Iterator<Integer> sieve() {
        return new Iterator<>() {
            private int current = 2;
            private final List<Integer> primes = new LinkedList<>();

            @Override
            public boolean hasNext() {
                return true; // Infinite
            }

            @Override
            public Integer next() {
                while (true) {
                    int candidate = current++;
                    boolean isPrime = true;
                    for (int prime : primes) {
                        if (candidate % prime == 0) {
                            isPrime = false;
                            break;
                        }
                    }
                    if (isPrime) {
                        primes.add(candidate);
                        return candidate;
                    }
                }
            }
        };
    }
}
