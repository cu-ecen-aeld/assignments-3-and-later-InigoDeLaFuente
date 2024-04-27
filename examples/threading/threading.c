#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/sysinfo.h>

// Optional: use these functions to add debug or error prints to your application
//#define DEBUG_LOG(msg,...)
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    usleep(thread_func_args->wait_to_obtain_ms*1000);
    int result = pthread_mutex_lock(thread_func_args->mutex);
    if (result != 0)
    {
        ERROR_LOG("Failed to obtain the mutex, error: %d",result);
    }
    else
    {
        DEBUG_LOG("Mutex obtained by calling thread");
        usleep(thread_func_args->wait_to_release_ms*1000);
        result = pthread_mutex_unlock(thread_func_args->mutex);
        if (result != 0)
        {
            ERROR_LOG("Failed to obtain the mutex, error: %d",result);
        }
        else
        {
            DEBUG_LOG("Mutex released by calling thread");
            thread_func_args->thread_complete_success = true;
        }
    }
    DEBUG_LOG("thread complete.");
    return (void*) thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */

    
    struct sysinfo sys_info;
    struct thread_data *thread_param = (struct thread_data*)malloc(sizeof(struct thread_data));
    if (thread_param == NULL)
    {
        ERROR_LOG("Failed to allocate thread_data");
        return false;
    }

    thread_param->mutex = mutex;
    thread_param->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_param->wait_to_release_ms = wait_to_release_ms;
    thread_param->thread_complete_success = false;

    int result = sysinfo(&sys_info);
    if(result != 0)
    {
        ERROR_LOG("Failed to get sysinfo, error: %d",result);
        return false;
    }

    DEBUG_LOG("Total Ram: %ldk\tFree: %ldk\n", sys_info.totalram / 1024,sys_info.freeram / 1024);

    result = pthread_create(thread, NULL, threadfunc, thread_param);
    if (result != 0)
    {
        ERROR_LOG("Failed to create the thread, error: %d",result);
        return false;
    }

    DEBUG_LOG("thread started succesfully with ID %ld",(unsigned long int)thread);

    return true;
}