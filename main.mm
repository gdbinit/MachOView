//
//  main.m
//  Mach-O Browser
//
//  Created by psaghelyi on 10/06/2010.
//


// every std IO operation needs to be paused until pipes are in use
NSCondition * pipeCondition;
int32_t numIOThread;

int 
main(int argc, const char *argv[])
{
  pipeCondition = [[NSCondition alloc]init];
  numIOThread = 0;
  return NSApplicationMain(argc, argv);
}
