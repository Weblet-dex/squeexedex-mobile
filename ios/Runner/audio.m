#include "audio.h"
#include "mm2.h"

// Working with audio from Objective-C in case it gives us advantage:
// "The bridge approach is preferred. As Chris Adamson said in media framework talk you have to Render unto Caesar the things that are Caesar's, and unto God the things that are God's i.e use C for C API and Swift for swifty things" - https://stackoverflow.com/a/44153603/257568

// Our use case is basically https://youtu.be/FlMaxen2eyw?t=272 - scheduling a number of buffers on a player.
// Nodes are source nodes, process nodes and destination nodes.
// There is an implicit mixer node (mainMixerNode).
// Player puts scheduled nodes at the end of the queue by default,
// use AVAudioPlayerNodeBufferInterrupts to overwrite the remaining queue instead.

// TBD: Fanfare60.wav from https://www2.cs.uic.edu/~i101/SoundFiles/ wouldn't load when copied to "maker.mp3",
// should investigate whether the wrong file extension is the reason,
// cf. https://github.com/SKKbySSK/audio_graph/issues/14#issuecomment-611627724
// plus we should now be able to implement checking the files when they are picked by the user.

// TBD: Consider loading streams from www.internet-radio.com

// TBD: Cache the AVAudioFile instances.

// TBD: Check again on whether we need the repeated `dex_engine connect` to adjust the `processingFormat`.
// Print the `processingFormat`?

// TBD: Consider implementing a scheduler loop in order to simplify the juggling
// of the background and foreground files.

#import <AVFoundation/AVFoundation.h>

#import <os/log.h>  // os_log

#include <stdatomic.h>  // atomic_fetch_add

static AVAudioEngine* dex_engine;
static AVAudioPlayerNode* dex_player;

/// Currently scheduled background file.
/// We keep a pointer to it in order to keep rescheduling it into the end of the `player` queue.
static AVAudioFile* dex_bg_file;

/// The number of files in the `player` queue.
static volatile atomic_int_fast32_t dex_scheduled = 0;

/// Increased wheneve the queue is reset, invalidating old completion handlers.
static volatile atomic_int_fast32_t dex_generation = 0;

/// Path to the assets/audio directory.
static NSString* dex_assets_audio;

/// Scheduled between files in order to hold to the `isPlayingProcessAssertion`.
void audio_ballast() {
    NSString* path = [NSString stringWithFormat:@"%@/%s", dex_assets_audio, "none.mp3"];  // “Standing by”

    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    NSError* err;
    AVAudioFile* file = [[AVAudioFile alloc] initForReading: url error: &err];
    if (err) {os_log (OS_LOG_DEFAULT, "audio_ballast] !file: %{public}@", err); return;}
    [dex_player scheduleSegment: file startingFrame: 60000 frameCount: 30000 atTime: nil completionHandler: nil];}

/// Invoked by completion handlers in order to maintain the background audio loop.
void audio_reschedule (int generation) {
  //os_log (OS_LOG_DEFAULT, "audio_reschedule] Entered..");
  int cur_generation = atomic_load (&dex_generation);
  if (generation != cur_generation) return;
  if (!dex_bg_file) return;

  // Need another thread in order not to trigger
  // "dispatch_sync called on queue already owned by current thread" in `AVAudioPlayerNodeImpl`
  dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
    //os_log (OS_LOG_DEFAULT, "audio_reschedule] Async..");
    int cur_generation = atomic_load (&dex_generation);
    if (generation != cur_generation) return;
    if (!dex_bg_file) return;

    // Stops the player. Should only do this when the `processingFormat` is known to change.
    //[dex_engine connect: dex_player to: [dex_engine mainMixerNode] format: dex_bg_file.processingFormat];

    //os_log (OS_LOG_DEFAULT, "audio_reschedule] Looping..");
    [dex_player scheduleFile: dex_bg_file atTime: nil completionHandler: ^() {audio_reschedule (generation);}];
    audio_ballast();});}

// TBD: dispatch_async, go off the main thread and run initialization in background.
void audio_init (const char* assets_ticking) {
  //os_log (OS_LOG_DEFAULT, "audio_init] Entered..");

  AVAudioEngine* engine = [[AVAudioEngine alloc] init];
  AVAudioPlayerNode* player = [[AVAudioPlayerNode alloc] init];
  [engine attachNode:player];

  const char* documents = documentDirectory();
  if (documents == NULL) {os_log (OS_LOG_DEFAULT, "audio_init] !documents"); return;}

  NSString* documents_ns = [[NSString alloc] initWithUTF8String: documents];
  NSArray* documents_a = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: documents_ns error: NULL];
  [documents_a enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* filename = (NSString*) obj;
    //os_log (OS_LOG_DEFAULT, "audio_init] Documents file: %{public}s", filename.UTF8String);
  }];

  if (!assets_ticking) {os_log (OS_LOG_DEFAULT, "audio_init] !assets_ticking"); return;}
  // TODO: change with actual sound-scheme samples
  const char* end = strstr (assets_ticking, "/tick-tock.mp3");
  if (!end) {os_log (OS_LOG_DEFAULT, "audio_init] !end"); return;}
  dex_assets_audio = [[[NSString alloc] initWithUTF8String: assets_ticking] substringToIndex: end - assets_ticking];
  //os_log (OS_LOG_DEFAULT, "audio_init] dex_assets_audio set to %{public}@", dex_assets_audio);

  // TODO: change with actual sound-scheme samples
  NSString* path = [NSString stringWithFormat:@"%@/%s", dex_assets_audio, "start.mp3"];  // “Standing by”

  NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
  NSError* err;
  AVAudioFile* file = [[AVAudioFile alloc] initForReading: url error: &err];
  if (err) {os_log (OS_LOG_DEFAULT, "audio_init] !file: %{public}@", err); return;}

  AVAudioMixerNode* mixer = [engine mainMixerNode];
  //os_log (OS_LOG_DEFAULT, "audio_init] Attaching..");
  // NB: Should investigate the format compatibility between the different possible audio sources.
  // cf. https://stackoverflow.com/questions/33484140/how-can-i-specify-the-format-of-avaudioengine-mic-input
  // Reconnecting the payer to the mixer before a new schedule seems to help with maintaining the format.
  [engine connect: player to: mixer format: file.processingFormat];

  //os_log (OS_LOG_DEFAULT, "audio_init] Category..");
  err = nil;
  [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error: &err];
  if (err) {os_log (OS_LOG_DEFAULT, "audio_init] !setCategory: %{public}@", err); return;}

  //os_log (OS_LOG_DEFAULT, "audio_init] Starting..");
  err = nil;
  [engine startAndReturnError: &err];
  if (err) {os_log (OS_LOG_DEFAULT, "audio_init] !start: %{public}@", err); return;}
  [player play];

  audio_volume ([[NSNumber alloc] initWithDouble: 0.1]);

  //os_log (OS_LOG_DEFAULT, "audio_init] Playing..");
  [player scheduleFile:file atTime:nil completionHandler:nil];

  //os_log (OS_LOG_DEFAULT, "audio_init] Done");
  dex_engine = engine;
  dex_player = player;}

void audio_resume() {
    NSError* err;
    [dex_engine startAndReturnError: &err];
    if (err) {os_log (OS_LOG_DEFAULT, "audio_resume]: %{public}@", err); return;}
    [dex_player play];
}

AVAudioFile* audio_load_file (NSString* rpath) {
  // See if there is a custom sound in Documents.
  const char* documents = documentDirectory();
  NSString* path = [NSString stringWithFormat:@"%s/%@", documents, rpath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath: path]) {
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    NSError* err;
    AVAudioFile* file = [[AVAudioFile alloc] initForReading: url error: &err];
    if (err) {
      os_log (OS_LOG_DEFAULT, "audio_load_file] Error loading a custom file %{public}@: %{public}@", path, err);
    } else {
      os_log (OS_LOG_DEFAULT, "audio_load_file] Loaded %{public}@", path);
      return file;}}

  path = [NSString stringWithFormat:@"%@/%@", dex_assets_audio, rpath];
  if (![fileManager fileExistsAtPath: path]) {
    os_log (OS_LOG_DEFAULT, "audio_load_file] No asset at %{public}@", path);
    return nil;}

  NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
  NSError* err;
  AVAudioFile* file = [[AVAudioFile alloc] initForReading: url error: &err];
  if (err) {
    os_log (OS_LOG_DEFAULT, "audio_load_file] Error loading asset %{public}@: %{public}@", path, err);
    return nil;}
  os_log (OS_LOG_DEFAULT, "audio_load_file] Loaded %{public}@", path);
  return file;}

int audio_bg (NSString* rpath) {
  if ([rpath length] == 0) {
    dex_bg_file = nil;
    return 0;}

  if (!dex_player) return -1;
  AVAudioFile* file = audio_load_file (rpath);
  if (!file) return -2;
  dex_bg_file = file;
  atomic_fetch_add (&dex_generation, 1);  // Invalidate previous completion handlers
  int generation = atomic_load (&dex_generation);
  [dex_player stop];  // Clears the queue
  [dex_engine connect: dex_player to: [dex_engine mainMixerNode] format: file.processingFormat];
  [dex_player play];
  [dex_player scheduleFile: file atTime: nil completionHandler: ^() {audio_reschedule (generation);}];
  audio_ballast();
  return 0;}

int audio_fg (NSString* rpath) {
  if (!dex_player) return -1;
  AVAudioFile* file = audio_load_file (rpath);
  if (!file) return -2;
  atomic_fetch_add (&dex_generation, 1);  // Invalidate previous completion handlers
  int generation = atomic_load (&dex_generation);
  [dex_player stop];  // Clears the queue
  [dex_engine connect: dex_player to: [dex_engine mainMixerNode] format: file.processingFormat];
  [dex_player play];
  [dex_player scheduleFile: file atTime: nil completionHandler: ^() {audio_reschedule (generation);}];
  audio_ballast();
  return 0;}

int audio_volume (NSNumber* volume) {
  if (!dex_player) return -1;
  [dex_player setVolume: [volume doubleValue]];
  return 0;}
