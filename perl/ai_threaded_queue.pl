use v5.40;
use Time::HiRes qw/time/;
use threads;
use Thread::Queue;

my $T0 = time;

# 1. Initialize the queue and set its maximum capacity to 10
my $q = Thread::Queue->new();
$q->limit = 10;

# 2. Define the worker function
sub worker_task {
    while (defined(my $item = $q->dequeue())) {
        say "[@{[sprintf '%12.6fs', time - $T0]}][Thread " . threads->tid() . "] Processing item: $item";
        sleep(1); # Simulate work
    }
}

# 3. Create worker threads (e.g., 5 workers to pull from the queue)
my @workers = map { threads->create(\&worker_task) } 1..5;

# 4. Enqueue 100 items
# The 'enqueue' call will automatically block when the queue reaches 10 items
for my $id (1..100) {
    say "Adding item $id to queue (Queue size: " . $q->pending() . ")";
    $q->enqueue($id);
}

# 5. Signal workers to stop and wait for completion
$q->end();
$q->join() for @workers;

say "All 100 items processed.";

__END__
Used an AI prompt to get something similar to what I wanted...
I am surprised, but I think my original threadQueue.pl wasn't actually backgrounding anything
