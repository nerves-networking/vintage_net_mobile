#include <ctype.h>
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <ei.h>

extern char **environ;

#define SOCKET_PATH "/tmp/vintage_net/pppd_comms"

static void encode_string(ei_x_buff *buff, const char *str)
{
    // Encode strings as binaries so that we get Elixir strings
    // NOTE: the strings that we encounter here are expected to be ASCII to
    //       my knowledge
    ei_x_encode_binary(buff, str, strlen(str));
}

static void encode_kv_string(ei_x_buff *buff, const char *key, const char *str)
{
    ei_x_encode_atom(buff, key);
    encode_string(buff, str);
}

static int count_elements(const char *str)
{
    if (*str == '\0')
        return 0;

    int n = 1;
    const char *p = str;
    while (*p != '\0') {
        if (*p == ' ')
            n++;
        p++;
    }
    return n;
}

static void encode_kv_list(ei_x_buff *buff, const char *key, const char *str)
{
    ei_x_encode_atom(buff, key);

    int n = count_elements(str);
    if (n > 0) {
        ei_x_encode_list_header(buff, n);

        const char *p = str;
        while (n > 1) {
            const char *end = strchr(p, ' ');
            ei_x_encode_binary(buff, p, end - p);
            p = end + 1;
            n--;
        }
        ei_x_encode_binary(buff, p, strlen(p));
    }

    ei_x_encode_empty_list(buff);
}

static int count_items(const char **p)
{
    int n = 0;
    while (*p != NULL) {
        n++;
        p++;
    }

    return n;
}

static void encode_env_kv(ei_x_buff *buff, const char *kv)
{
    char key[32];

    const char *equal = strchr(kv, '=');
    if (equal == NULL)
        return;

    size_t keylen = equal - kv;
    if (keylen >= sizeof(key))
        keylen = sizeof(key) - 1;
    memcpy(key, kv, keylen);
    key[keylen] = '\0';

    const char *value = equal + 1;

    encode_kv_string(buff, key, value);
}

static void encode_environ(ei_x_buff *buff)
{
    int kv_to_encode = count_items(environ);
    ei_x_encode_map_header(buff, kv_to_encode);

    for (char **p = environ;
        *p != NULL;
        p++) {
        encode_env_kv(buff, *p);
    }
}

static void encode_args(ei_x_buff *buff, int argc, char *argv[])
{
    ei_x_encode_list_header(buff, argc);

    int i;
    for (i = 0; i < argc; i++)
        encode_string(buff, argv[i]);

    ei_x_encode_empty_list(buff);
}

int main(int argc, char *argv[])
{
    int fd = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (fd < 0)
        err(EXIT_FAILURE, "socket");

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) == -1)
        err(EXIT_FAILURE, "connect");

    ei_x_buff buff;
    if (ei_x_new_with_version(&buff) < 0)
        err(EXIT_FAILURE, "ei_x_new_with_version");


    ei_x_encode_tuple_header(&buff, 2);

    encode_args(&buff, argc, argv);
    encode_environ(&buff);

    ssize_t rc = write(fd, buff.buff, buff.index);
    if (rc < 0)
        err(EXIT_FAILURE, "write");

    if (rc != buff.index)
        errx(EXIT_FAILURE, "write wasn't able to send %d chars all at once!", buff.index);

    close(fd);
    return 0;
}

