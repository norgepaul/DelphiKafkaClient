unit Kafka.Lib;

interface

uses
  Kafka.Types;

const
  {$IFDEF MSWINDOWS}
  LIBFILE = 'librdkafka.dll';
  {$ELSE}
  LIBFILE = 'librdkafka.so';
  {$ENDIF}

  (*
    * librdkafka - Apache Kafka C library
    *
    * Copyright (c) 2012-2013 Magnus Edenhill
    * All rights reserved.
    *
    * Redistribution and use in source and binary forms, with or without
    * modification, are permitted provided that the following conditions are met:
    *
    * 1. Redistributions of source code must retain the above copyright notice,
    *    this list of conditions and the following disclaimer.
    * 2. Redistributions in binary form must reproduce the above copyright notice,
    *    this list of conditions and the following disclaimer in the documentation
    *    and/or other materials provided with the distribution.
    *
    * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
    * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    * POSSIBILITY OF SUCH DAMAGE.
  *)

  (* *
    * @file rdkafka.h
    * @brief Apache Kafka C/C++ consumer and producer client library.
    *
    * rdkafka.h contains the public API for librdkafka.
    * The API is documented in this file as comments prefixing the function, type,
    * enum, define, etc.
    *
    * @sa For the C++ interface see rdkafkacpp.h
    *
    * @tableofcontents
  *)

  (* *
    * @name librdkafka version
    * @{
    *
    *
  *)

  (* *
    * @brief librdkafka version
    *
    * Interpreted as hex \c MM.mm.rr.xx:
    *  - MM = Major
    *  - mm = minor
    *  - rr = revision
    *  - xx = pre-release id (0xff is the final release)
    *
    * E.g.: \c 0x000801ff = 0.8.1
    *
    * @remark This value should only be used during compile time,
    *         for runtime checks of version use rd_kafka_version()
  *)
  // const
  // RD_KAFKA_VERSION = $00090200;

  (* *
    * @brief Returns the librdkafka version as integer.
    *
    * @returns Version integer.
    *
    * @sa See RD_KAFKA_VERSION for how to parse the integer format.
    * @sa Use rd_kafka_version_str() to retreive the version as a string.
  *)

function rd_kafka_version: integer; cdecl;

(* *
  * @brief Returns the librdkafka version as string.
  *
  * @returns Version string
*)

function rd_kafka_version_str: PAnsiChar; cdecl;

(* *@} *)

(* *
  * @name Constants, errors, types
  * @{
  *
  *
*)

(* *
  * @enum rd_kafka_type_t
  *
  * @brief rd_kafka_t handle type.
  *
  * @sa rd_kafka_new()
*)
type

  rd_kafka_type_t = (RD_KAFKA_PRODUCER, (* *< Producer client *)
    RD_KAFKA_CONSUMER (* *< Consumer client *)
    );

  (* *
    * @enum Timestamp types
    *
    * @sa rd_kafka_message_timestamp()
  *)
type
  rd_kafka_timestamp_type_t = (RD_KAFKA_TIMESTAMP_NOT_AVAILABLE, (* *< Timestamp not available *)
    RD_KAFKA_TIMESTAMP_CREATE_TIME, (* *< Message creation time *)
    RD_KAFKA_TIMESTAMP_LOG_APPEND_TIME (* *< Log append time *)
    );
  prd_kafka_timestamp_type_t = ^rd_kafka_timestamp_type_t;

  (* *
    * @brief Retrieve supported debug contexts for use with the \c \cdebug\c
    *        configuration property. (runtime)
    *
    * @returns Comma-separated list of available debugging contexts.
  *)

function rd_kafka_get_debug_contexts: PAnsiChar; cdecl;

(* *
  * @brief Supported debug contexts. (compile time)
  *
  * @deprecated This compile time value may be outdated at runtime due to
  *             linking another version of the library.
  *             Use rd_kafka_get_debug_contexts() instead.
*)
const
  RD_KAFKA_DEBUG_CONTEXTS = 'all,generic,broker,topic,metadata,queue,msg,protocol,cgrp,security,fetch,feature';

  (* @cond NO_DOC *)
  (* Private types to provide ABI compatibility *)
type
  rd_kafka_s = record
  end;

  rd_kafka_t = rd_kafka_s;
  prd_kafka_t = ^rd_kafka_t;

  rd_kafka_topic_s = record
  end;

  rd_kafka_topic_t = rd_kafka_topic_s;
  prd_kafka_topic_t = ^rd_kafka_topic_t;

  rd_kafka_conf_s = record
  end;

  rd_kafka_conf_t = rd_kafka_conf_s;
  prd_kafka_conf_t = ^rd_kafka_conf_t;

  rd_kafka_topic_conf_s = record
  end;

  rd_kafka_topic_conf_t = rd_kafka_topic_conf_s;
  prd_kafka_topic_conf_t = ^rd_kafka_topic_conf_t;

  rd_kafka_queue_s = record
  end;

  rd_kafka_queue_t = rd_kafka_queue_s;
  prd_kafka_queue_t = ^rd_kafka_queue_t;
  (* @endcond *)

  (* *
    * @enum rd_kafka_resp_err_t
    * @brief Error codes.
    *
    * The negative error codes delimited by two underscores
    * (\c RD_KAFKA_RESP_ERR__..) denotes errors internal to librdkafka and are
    * displayed as \c \cLocal: \<error string..\>\c, while the error codes
    * delimited by a single underscore (\c RD_KAFKA_RESP_ERR_..) denote broker
    * errors and are displayed as \c \cBroker: \<error string..\>\c.
    *
    * @sa Use rd_kafka_err2str() to translate an error code a human readable string
  *)
type
  rd_kafka_resp_err_t = (
    (* Internal errors to rdkafka: *)
    (* * Begin internal error codes *)
    RD_KAFKA_RESP_ERR__BEGIN = -200,
    (* * Received message is incorrect *)
    RD_KAFKA_RESP_ERR__BAD_MSG = -199,
    (* * Bad/unknown compression *)
    RD_KAFKA_RESP_ERR__BAD_COMPRESSION = -198,
    (* * Broker is going away *)
    RD_KAFKA_RESP_ERR__DESTROY = -197,
    (* * Generic failure *)
    RD_KAFKA_RESP_ERR__FAIL = -196,
    (* * Broker transport failure *)
    RD_KAFKA_RESP_ERR__TRANSPORT = -195,
    (* * Critical system resource *)
    RD_KAFKA_RESP_ERR__CRIT_SYS_RESOURCE = -194,
    (* * Failed to resolve broker *)
    RD_KAFKA_RESP_ERR__RESOLVE = -193,
    (* * Produced message timed out *)
    RD_KAFKA_RESP_ERR__MSG_TIMED_OUT = -192,
    (* * Reached the end of the topic+partition queue on
      * the broker. Not really an error. *)
    RD_KAFKA_RESP_ERR__PARTITION_EOF = -191,
    (* * Permanent: Partition does not exist in cluster. *)
    RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION = -190,
    (* * File or filesystem error *)
    RD_KAFKA_RESP_ERR__FS = -189,
    (* * Permanent: Topic does not exist in cluster. *)
    RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC = -188,
    (* * All broker connections are down. *)
    RD_KAFKA_RESP_ERR__ALL_BROKERS_DOWN = -187,
    (* * Invalid argument, or invalid configuration *)
    RD_KAFKA_RESP_ERR__INVALID_ARG = -186,
    (* * Operation timed out *)
    RD_KAFKA_RESP_ERR__TIMED_OUT = -185,
    (* * Queue is full *)
    RD_KAFKA_RESP_ERR__QUEUE_FULL = -184,
    (* * ISR count < required.acks *)
    RD_KAFKA_RESP_ERR__ISR_INSUFF = -183,
    (* * Broker node update *)
    RD_KAFKA_RESP_ERR__NODE_UPDATE = -182,
    (* * SSL error *)
    RD_KAFKA_RESP_ERR__SSL = -181,
    (* * Waiting for coordinator to become available. *)
    RD_KAFKA_RESP_ERR__WAIT_COORD = -180,
    (* * Unknown client group *)
    RD_KAFKA_RESP_ERR__UNKNOWN_GROUP = -179,
    (* * Operation in progress *)
    RD_KAFKA_RESP_ERR__IN_PROGRESS = -178,
    (* * Previous operation in progress, wait for it to finish. *)
    RD_KAFKA_RESP_ERR__PREV_IN_PROGRESS = -177,
    (* * This operation would interfere with an existing subscription *)
    RD_KAFKA_RESP_ERR__EXISTING_SUBSCRIPTION = -176,
    (* * Assigned partitions (rebalance_cb) *)
    RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS = -175,
    (* * Revoked partitions (rebalance_cb) *)
    RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS = -174,
    (* * Conflicting use *)
    RD_KAFKA_RESP_ERR__CONFLICT = -173,
    (* * Wrong state *)
    RD_KAFKA_RESP_ERR__STATE = -172,
    (* * Unknown protocol *)
    RD_KAFKA_RESP_ERR__UNKNOWN_PROTOCOL = -171,
    (* * Not implemented *)
    RD_KAFKA_RESP_ERR__NOT_IMPLEMENTED = -170,
    (* * Authentication failure *)
    RD_KAFKA_RESP_ERR__AUTHENTICATION = -169,
    (* * No stored offset *)
    RD_KAFKA_RESP_ERR__NO_OFFSET = -168,
    (* * Outdated *)
    RD_KAFKA_RESP_ERR__OUTDATED = -167,
    (* * Timed out in queue *)
    RD_KAFKA_RESP_ERR__TIMED_OUT_QUEUE = -166,

    (* * End internal error codes *)
    RD_KAFKA_RESP_ERR__END = -100,

    (* Kafka broker errors: *)
    (* * Unknown broker error *)
    RD_KAFKA_RESP_ERR_UNKNOWN = -1,
    (* * Success *)
    RD_KAFKA_RESP_ERR_NO_ERROR = 0,
    (* * Offset out of range *)
    RD_KAFKA_RESP_ERR_OFFSET_OUT_OF_RANGE = 1,
    (* * Invalid message *)
    RD_KAFKA_RESP_ERR_INVALID_MSG = 2,
    (* * Unknown topic or partition *)
    RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART = 3,
    (* * Invalid message size *)
    RD_KAFKA_RESP_ERR_INVALID_MSG_SIZE = 4,
    (* * Leader not available *)
    RD_KAFKA_RESP_ERR_LEADER_NOT_AVAILABLE = 5,
    (* * Not leader for partition *)
    RD_KAFKA_RESP_ERR_NOT_LEADER_FOR_PARTITION = 6,
    (* * Request timed out *)
    RD_KAFKA_RESP_ERR_REQUEST_TIMED_OUT = 7,
    (* * Broker not available *)
    RD_KAFKA_RESP_ERR_BROKER_NOT_AVAILABLE = 8,
    (* * Replica not available *)
    RD_KAFKA_RESP_ERR_REPLICA_NOT_AVAILABLE = 9,
    (* * Message size too large *)
    RD_KAFKA_RESP_ERR_MSG_SIZE_TOO_LARGE = 10,
    (* * StaleControllerEpochCode *)
    RD_KAFKA_RESP_ERR_STALE_CTRL_EPOCH = 11,
    (* * Offset metadata string too large *)
    RD_KAFKA_RESP_ERR_OFFSET_METADATA_TOO_LARGE = 12,
    (* * Broker disconnected before response received *)
    RD_KAFKA_RESP_ERR_NETWORK_EXCEPTION = 13,
    (* * Group coordinator load in progress *)
    RD_KAFKA_RESP_ERR_GROUP_LOAD_IN_PROGRESS = 14,
    (* * Group coordinator not available *)
    RD_KAFKA_RESP_ERR_GROUP_COORDINATOR_NOT_AVAILABLE = 15,
    (* * Not coordinator for group *)
    RD_KAFKA_RESP_ERR_NOT_COORDINATOR_FOR_GROUP = 16,
    (* * Invalid topic *)
    RD_KAFKA_RESP_ERR_TOPIC_EXCEPTION = 17,
    (* * Message batch larger than configured server segment size *)
    RD_KAFKA_RESP_ERR_RECORD_LIST_TOO_LARGE = 18,
    (* * Not enough in-sync replicas *)
    RD_KAFKA_RESP_ERR_NOT_ENOUGH_REPLICAS = 19,
    (* * Message(s) written to insufficient number of in-sync replicas *)
    RD_KAFKA_RESP_ERR_NOT_ENOUGH_REPLICAS_AFTER_APPEND = 20,
    (* * Invalid required acks value *)
    RD_KAFKA_RESP_ERR_INVALID_REQUIRED_ACKS = 21,
    (* * Specified group generation id is not valid *)
    RD_KAFKA_RESP_ERR_ILLEGAL_GENERATION = 22,
    (* * Inconsistent group protocol *)
    RD_KAFKA_RESP_ERR_INCONSISTENT_GROUP_PROTOCOL = 23,
    (* * Invalid group.id *)
    RD_KAFKA_RESP_ERR_INVALID_GROUP_ID = 24,
    (* * Unknown member *)
    RD_KAFKA_RESP_ERR_UNKNOWN_MEMBER_ID = 25,
    (* * Invalid session timeout *)
    RD_KAFKA_RESP_ERR_INVALID_SESSION_TIMEOUT = 26,
    (* * Group rebalance in progress *)
    RD_KAFKA_RESP_ERR_REBALANCE_IN_PROGRESS = 27,
    (* * Commit offset data size is not valid *)
    RD_KAFKA_RESP_ERR_INVALID_COMMIT_OFFSET_SIZE = 28,
    (* * Topic authorization failed *)
    RD_KAFKA_RESP_ERR_TOPIC_AUTHORIZATION_FAILED = 29,
    (* * Group authorization failed *)
    RD_KAFKA_RESP_ERR_GROUP_AUTHORIZATION_FAILED = 30,
    (* * Cluster authorization failed *)
    RD_KAFKA_RESP_ERR_CLUSTER_AUTHORIZATION_FAILED = 31,
    (* * Invalid timestamp *)
    RD_KAFKA_RESP_ERR_INVALID_TIMESTAMP = 32,
    (* * Unsupported SASL mechanism *)
    RD_KAFKA_RESP_ERR_UNSUPPORTED_SASL_MECHANISM = 33,
    (* * Illegal SASL state *)
    RD_KAFKA_RESP_ERR_ILLEGAL_SASL_STATE = 34,
    (* * Unuspported version *)
    RD_KAFKA_RESP_ERR_UNSUPPORTED_VERSION = 35,

    RD_KAFKA_RESP_ERR_END_ALL);

  (* *
    * @brief Error code value, name and description.
    *        Typically for use with language bindings to automatically expose
    *        the full set of librdkafka error codes.
  *)
  rd_kafka_err_desc = record
    code: rd_kafka_resp_err_t; (* *< Error code *)
    name: PAnsiChar; (* *< Error name, same as code enum sans prefix *)
    desc: PAnsiChar; (* *< Human readable error description. *)
  end;

  prd_kafka_err_desc = ^rd_kafka_err_desc;
  (* *
    * @brief Returns the full list of error codes.
  *)

procedure rd_kafka_get_err_descs(var errdescs: prd_kafka_err_desc; var cntp: NativeUInt); cdecl;

(* *
  * @brief Returns a human readable representation of a kafka error.
  *
  * @param err Error code to translate
*)

function rd_kafka_err2str(err: rd_kafka_resp_err_t): PAnsiChar; cdecl;

(* *
  * @brief Returns the error code name (enum name).
  *
  * @param err Error code to translate
*)

function rd_kafka_err2name(err: rd_kafka_resp_err_t): PAnsiChar; cdecl;

(* *
  * @brief Returns the last error code generated by a legacy API call
  *        in the current thread.
  *
  * The legacy APIs are the ones using errno to propagate error value, namely:
  *  - rd_kafka_topic_new()
  *  - rd_kafka_consume_start()
  *  - rd_kafka_consume_stop()
  *  - rd_kafka_consume()
  *  - rd_kafka_consume_batch()
  *  - rd_kafka_consume_callback()
  *  - rd_kafka_consume_queue()
  *  - rd_kafka_produce()
  *
  * The main use for this function is to avoid converting system \p errno
  * values to rd_kafka_resp_err_t codes for legacy APIs.
  *
  * @remark The last error is stored per-thread, if multiple rd_kafka_t handles
  *         are used in the same application thread the developer needs to
  *         make sure rd_kafka_last_error() is called immediately after
  *         a failed API call.
*)

function rd_kafka_last_error: rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Converts the system errno value \p errnox to a rd_kafka_resp_err_t
  *        error code upon failure from the following functions:
  *  - rd_kafka_topic_new()
  *  - rd_kafka_consume_start()
  *  - rd_kafka_consume_stop()
  *  - rd_kafka_consume()
  *  - rd_kafka_consume_batch()
  *  - rd_kafka_consume_callback()
  *  - rd_kafka_consume_queue()
  *  - rd_kafka_produce()
  *
  * @param errnox  System errno value to convert
  *
  * @returns Appropriate error code for \p errnox
  *
  * @remark A better alternative is to call rd_kafka_last_error() immediately
  *         after any of the above functions return -1 or NULL.
  *
  * @sa rd_kafka_last_error()
*)

function rd_kafka_errno2err(errnox: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Returns the thread-local system errno
  *
  * On most platforms this is the same as \p errno but in case of different
  * runtimes between library and application (e.g., Windows static DLLs)
  * this provides a means for expsing the errno librdkafka uses.
  *
  * @remark The value is local to the current calling thread.
*)

function rd_kafka_errno: integer; cdecl;

(* *
  * @brief Topic+Partition place holder
  *
  * Generic place holder for a Topic+Partition and its related information
  * used for multiple purposes:
  *   - consumer offset (see rd_kafka_commit(), et.al.)
  *   - group rebalancing callback (rd_kafka_conf_set_rebalance_cb())
  *   - offset commit result callback (rd_kafka_conf_set_offset_commit_cb())
*)

(* *
  * @brief Generic place holder for a specific Topic+Partition.
  *
  * @sa rd_kafka_topic_partition_list_new()
*)
type
  rd_kafka_topic_partition_s = record
    topic: PAnsiChar; (* *< Topic name *)
    partition: Int32; (* *< Partition *)
    offset: Int64; (* *< Offset *)
    metadata: Pointer; (* *< Metadata *)
    metadata_size: NativeUInt; (* *< Metadata size *)
    opaque: Pointer; (* *< Application opaque *)
    err: rd_kafka_resp_err_t; (* *< Error code, depending on use. *)
    _private: Pointer; (* *< INTERNAL USE ONLY,
      *   INITIALIZE TO ZERO, DO NOT TOUCH *)
  end;

  rd_kafka_topic_partition_t = rd_kafka_topic_partition_s;
  prd_kafka_topic_partition_t = ^rd_kafka_topic_partition_t;

  (* *
    * @brief Destroy a rd_kafka_topic_partition_t.
    * @remark This must not be called for elements in a topic partition list.
  *)

procedure rd_kafka_topic_partition_destroy(rktpar: prd_kafka_topic_partition_t); cdecl;

(* *
  * @brief A growable list of Topic+Partitions.
  *
*)
type
  rd_kafka_topic_partition_list_s = record
    cnt: integer; (* *< Current number of elements *)
    size: integer; (* *< Current allocated size *)
    elems: prd_kafka_topic_partition_t; (* *< Element array[] *)
  end;

  rd_kafka_topic_partition_list_t = rd_kafka_topic_partition_list_s;
  prd_kafka_topic_partition_list_t = ^rd_kafka_topic_partition_list_t;

  (* *
    * @brief Create a new list/vector Topic+Partition container.
    *
    * @param size  Initial allocated size used when the expected number of
    *              elements is known or can be estimated.
    *              Avoids reallocation and possibly relocation of the
    *              elems array.
    *
    * @returns A newly allocated Topic+Partition list.
    *
    * @remark Use rd_kafka_topic_partition_list_destroy() to free all resources
    *         in use by a list and the list itself.
    * @sa     rd_kafka_topic_partition_list_add()
  *)

function rd_kafka_topic_partition_list_new(size: integer): prd_kafka_topic_partition_list_t; cdecl;

(* *
  * @brief Free all resources used by the list and the list itself.
*)

procedure rd_kafka_topic_partition_list_destroy(rkparlist: prd_kafka_topic_partition_list_t); cdecl;

(* *
  * @brief Add topic+partition to list
  *
  * @param rktparlist List to extend
  * @param topic      Topic name (copied)
  * @param partition  Partition id
  *
  * @returns The object which can be used to fill in additionals fields.
*)

function rd_kafka_topic_partition_list_add(rktparlist: prd_kafka_topic_partition_list_t; topic: PAnsiChar; partition: Int32): prd_kafka_topic_partition_t; cdecl;

(* *
  * @brief Add range of partitions from \p start to \p stop inclusive.
  *
  * @param rktparlist List to extend
  * @param topic      Topic name (copied)
  * @param start      Start partition of range
  * @param stop       Last partition of range (inclusive)
*)

procedure rd_kafka_topic_partition_list_add_range(rktparlist: prd_kafka_topic_partition_list_t; topic: PAnsiChar; start: Int32; stop: Int32); cdecl;

(* *
  * @brief Delete partition from list.
  *
  * @param rktparlist List to modify
  * @param topic      Topic name to match
  * @param partition  Partition to match
  *
  * @returns 1 if partition was found (and removed), else 0.
  *
  * @remark Any held indices to elems[] are unusable after this call returns 1.
*)

function rd_kafka_topic_partition_list_del(rktparlist: prd_kafka_topic_partition_list_t; topic: PAnsiChar; partition: Int32): integer; cdecl;

(* *
  * @brief Delete partition from list by elems[] index.
  *
  * @returns 1 if partition was found (and removed), else 0.
  *
  * @sa rd_kafka_topic_partition_list_del()
*)

function rd_kafka_topic_partition_list_del_by_idx(rktparlist: prd_kafka_topic_partition_list_t; idx: integer): integer; cdecl;

(* *
  * @brief Make a copy of an existing list.
  *
  * @param src   The existing list to copy.
  *
  * @returns A new list fully populated to be identical to \p src
*)

function rd_kafka_topic_partition_list_copy(src: prd_kafka_topic_partition_list_t): prd_kafka_topic_partition_list_t; cdecl;

(* *
  * @brief Set offset to \p offset for \p topic and \p partition
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success or
  *          RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION if \p partition was not found
  *          in the list.
*)

function rd_kafka_topic_partition_list_set_offset(rktparlist: prd_kafka_topic_partition_list_t; topic: PAnsiChar; partition: Int32; offset: Int64): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Find element by \p topic and \p partition.
  *
  * @returns a pointer to the first matching element, or NULL if not found.
*)

function rd_kafka_topic_partition_list_find(rktparlist: prd_kafka_topic_partition_list_t; topic: PAnsiChar; partition: Int32): prd_kafka_topic_partition_t; cdecl;

(* *@} *)

(* *
  * @name Kafka messages
  * @{
  *
*)

(* FIXME: This doesn't show up in docs for some reason *)
(* "Compound rd_kafka_message_t is not documented." *)
(* *
  * @brief A Kafka message as returned by the \c rd_kafka_consume*() family
  *        of functions as well as provided to the Producer \c dr_msg_cb().
  *
  * For the consumer this object has two purposes:
  *  - provide the application with a consumed message. (\c err == 0)
  *  - report per-topic+partition consumer errors (\c err != 0)
  *
  * The application must check \c err to decide what action to take.
  *
  * When the application is finished with a message it must call
  * rd_kafka_message_destroy() unless otherwise noted.
*)
type
  rd_kafka_message_s = record
    err: rd_kafka_resp_err_t; (* *< Non-zero for error signaling. *)
    rkt: prd_kafka_topic_t; (* *< Topic *)
    partition: Int32; (* *< Partition *)
    payload: Pointer; (* *< Producer: original message payload.
      * Consumer: Depends on the value of \c err :
      * - \c err==0: Message payload.
      * - \c err!=0: Error string *)
    len: NativeUInt; (* *< Depends on the value of \c err :
      * - \c err==0: Message payload length
      * - \c err!=0: Error string length *)
    key: Pointer; (* *< Depends on the value of \c err :
      * - \c err==0: Optional message key *)
    key_len: NativeUInt; (* *< Depends on the value of \c err :
      * - \c err==0: Optional message key length *)
    offset: Int64; (* *< Consume:
      * - Message offset (or offset for error
      *   if \c err!=0 if applicable).
      * - dr_msg_cb:
      *   Message offset assigned by broker.
      *   If \c produce.offset.report is set then
      *   each message will have this field set,
      *   otherwise only the last message in
      *   each produced internal batch will
      *   have this field set, otherwise 0. *)
    _private: Pointer; (* *< Consume:
      *  - rdkafka private pointer: DO NOT MODIFY
      *  - dr_msg_cb:
      *    msg_opaque from produce() call *)
  end;

  rd_kafka_message_t = rd_kafka_message_s;
  prd_kafka_message_t = ^rd_kafka_message_t;

  (* *
    * @brief Frees resources for \p rkmessage and hands ownership back to rdkafka.
  *)

procedure rd_kafka_message_destroy(rkmessage: prd_kafka_message_t); cdecl;

(* *
  * @brief Returns the error string for an errored rd_kafka_message_t or NULL if
  *        there was no error.
*)
function rd_kafka_message_errstr(rkmessage: prd_kafka_message_t): PAnsiChar; inline;

(* *
  * @brief Returns the message timestamp for a consumed message.
  *
  * The timestamp is the number of milliseconds since the epoch (UTC).
  *
  * \p tstype is updated to indicate the type of timestamp.
  *
  * @returns message timestamp, or -1 if not available.
  *
  * @remark Message timestamps require broker version 0.10.0 or later.
*)

function rd_kafka_message_timestamp(rkmessage: prd_kafka_message_t; tstype: prd_kafka_timestamp_type_t): Int64; cdecl;

(* *@} *)

(* *
  * @name Configuration interface
  * @{
  *
  * @brief Main/global configuration property interface
  *
*)

(* *
  * @enum rd_kafka_conf_res_t
  * @brief Configuration result type
*)
type
  rd_kafka_conf_res_t = (RD_KAFKA_CONF_UNKNOWN = -2, (* *< Unknown configuration name. *)
    RD_KAFKA_CONF_INVALID = -1, (* *< Invalid configuration value. *)
    RD_KAFKA_CONF_OK = 0 (* *< Configuration okay *)
    );

  (* *
    * @brief Create configuration object.
    *
    * When providing your own configuration to the \c rd_kafka_*_new_*() calls
    * the rd_kafka_conf_t objects needs to be created with this function
    * which will set up the defaults.
    * I.e.:
    * @code
    *   rd_kafka_conf_t *myconf;
    *   rd_kafka_conf_res_t res;
    *
    *   myconf = rd_kafka_conf_new();
    *   res = rd_kafka_conf_set(myconf, "socket.timeout.ms", "600",
    *                           errstr, sizeof(errstr));
    *   if (res != RD_KAFKA_CONF_OK)
    *      die("%s\n", errstr);
    *
    *   rk = rd_kafka_new(..., myconf);
    * @endcode
    *
    * Please see CONFIGURATION.md for the default settings or use
    * rd_kafka_conf_properties_show() to provide the information at runtime.
    *
    * The properties are identical to the Apache Kafka configuration properties
    * whenever possible.
    *
    * @returns A new rd_kafka_conf_t object with defaults set.
    *
    * @sa rd_kafka_conf_set(), rd_kafka_conf_destroy()
  *)

function rd_kafka_conf_new: prd_kafka_conf_t; cdecl;

(* *
  * @brief Destroys a conf object.
*)

procedure rd_kafka_conf_destroy(conf: prd_kafka_conf_t); cdecl;

(* *
  * @brief Creates a copy/duplicate of configuration object \p conf
*)

function rd_kafka_conf_dup(conf: prd_kafka_conf_t): prd_kafka_conf_t; cdecl;

(* *
  * @brief Sets a configuration property.
  *
  * \p must have been previously created with rd_kafka_conf_new().
  *
  * Returns \c rd_kafka_conf_res_t to indicate success or failure.
  * In case of failure \p errstr is updated to contain a human readable
  * error string.
*)

function rd_kafka_conf_set(conf: prd_kafka_conf_t; name: PAnsiChar; value: PAnsiChar; errstr: PAnsiChar; errstr_size: NativeUInt): rd_kafka_conf_res_t; cdecl;

(* *
  * @brief Enable event sourcing.
  * \p events is a bitmask of \c RD_KAFKA_EVENT_* of events to enable
  * for consumption by `rd_kafka_queue_poll()`.
*)

procedure rd_kafka_conf_set_events(conf: prd_kafka_conf_t; events: integer); cdecl;

(* *
  @deprecated See rd_kafka_conf_set_dr_msg_cb()
*)

type
  dr_cb = procedure(rk: prd_kafka_t; payload: Pointer; len: NativeUInt; err: rd_kafka_resp_err_t; opaque: Pointer; msg_opaque: Pointer); cdecl;
  procedure rd_kafka_conf_set_dr_cb(conf: prd_kafka_conf_t; cb: dr_cb); cdecl;

(* *
  * @brief \b Producer: Set delivery report callback in provided \p conf object.
  *
  * The delivery report callback will be called once for each message
  * accepted by rd_kafka_produce() (et.al) with \p err set to indicate
  * the result of the produce request.
  *
  * The callback is called when a message is succesfully produced or
  * if librdkafka encountered a permanent failure, or the retry counter for
  * temporary errors has been exhausted.
  *
  * An application must call rd_kafka_poll() at regular intervals to
  * serve queued delivery report callbacks.
*)

type
  dr_msg_cb = procedure(rk: prd_kafka_t; rkmessage: prd_kafka_message_t; opaque: Pointer); cdecl;
  procedure rd_kafka_conf_set_dr_msg_cb(conf: prd_kafka_conf_t; cb: dr_msg_cb); cdecl;

(* *
  * @brief \b Consumer: Set consume callback for use with rd_kafka_consumer_poll()
  *
*)

type
  set_consume_cb = procedure(rkmessage: prd_kafka_message_t; opaque: Pointer); cdecl;

procedure rd_kafka_conf_set_consume_cb(conf: prd_kafka_conf_t; cb: set_consume_cb); cdecl;

(* *
  * @brief \b Consumer: Set rebalance callback for use with
  *                     coordinated consumer group balancing.
  *
  * The \p err field is set to either RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS
  * or RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS and 'partitions'
  * contains the full partition set that was either assigned or revoked.
  *
  * Registering a \p rebalance_cb turns off librdkafka's automatic
  * partition assignment/revocation and instead delegates that responsibility
  * to the application's \p rebalance_cb.
  *
  * The rebalance callback is responsible for updating librdkafka's
  * assignment set based on the two events: RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS
  * and RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS but should also be able to handle
  * arbitrary rebalancing failures where \p err is neither of those.
  * @remark In this latter case (arbitrary error), the application must
  *         call rd_kafka_assign(rk, NULL) to synchronize state.
  *
  * Without a rebalance callback this is done automatically by librdkafka
  * but registering a rebalance callback gives the application flexibility
  * in performing other operations along with the assinging/revocation,
  * such as fetching offsets from an alternate location (on assign)
  * or manually committing offsets (on revoke).
  *
  * @remark The \p partitions list is destroyed by librdkafka on return
  *         return from the rebalance_cb and must not be freed or
  *         saved by the application.
  *
  * The following example shows the application's responsibilities:
  * @code
  *    static void rebalance_cb (rd_kafka_t *rk, rd_kafka_resp_err_t err,
  *                              rd_kafka_topic_partition_list_t *partitions,
  *                              void *opaque) {
  *
  *        switch (err)
  *        {
  *          case RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS:
  *             // application may load offets from arbitrary external
  *             // storage here and update \p partitions
  *
  *             rd_kafka_assign(rk, partitions);
  *             break;
  *
  *          case RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS:
  *             if (manual_commits) // Optional explicit manual commit
  *                 rd_kafka_commit(rk, partitions, 0); // sync commit
  *
  *             rd_kafka_assign(rk, NULL);
  *             break;
  *
  *          default:
  *             handle_unlikely_error(err);
  *             rd_kafka_assign(rk, NULL); // sync state
  *             break;
  *         }
  *    }
  * @endcode
*)

type
  rebalance_cb = procedure(rk: prd_kafka_t; err: rd_kafka_resp_err_t; partitions: prd_kafka_topic_partition_list_t; opaque: Pointer); cdecl;

procedure rd_kafka_conf_set_rebalance_cb(conf: prd_kafka_conf_t; cb: rebalance_cb); cdecl;

(* *
  * @brief \b Consumer: Set offset commit callback for use with consumer groups.
  *
  * The results of automatic or manual offset commits will be scheduled
  * for this callback and is served by rd_kafka_consumer_poll().
  *
  * If no partitions had valid offsets to commit this callback will be called
  * with \p err == RD_KAFKA_RESP_ERR__NO_OFFSET which is not to be considered
  * an error.
  *
  * The \p offsets list contains per-partition information:
  *   - \c offset: committed offset (attempted)
  *   - \c err:    commit error
*)

type
  offset_commit_cb = procedure(rk: prd_kafka_t; err: rd_kafka_resp_err_t; offsets: prd_kafka_topic_partition_list_t; opaque: Pointer); cdecl;

procedure rd_kafka_conf_set_offset_commit_cb(conf: prd_kafka_conf_t; cb: offset_commit_cb); cdecl;

(* *
  * @brief Set error callback in provided conf object.
  *
  * The error callback is used by librdkafka to signal critical errors
  * back to the application.
  *
  * If no \p error_cb is registered then the errors will be logged instead.
*)

type
  error_cb = procedure(rk: prd_kafka_t; err: integer; reason: PAnsiChar; opaque: Pointer); cdecl;
procedure rd_kafka_conf_set_error_cb(conf: prd_kafka_conf_t; cb: error_cb); cdecl;

(* *
  * @brief Set throttle callback.
  *
  * The throttle callback is used to forward broker throttle times to the
  * application for Produce and Fetch (consume) requests.
  *
  * Callbacks are triggered whenever a non-zero throttle time is returned by
  * the broker, or when the throttle time drops back to zero.
  *
  * An application must call rd_kafka_poll() or rd_kafka_consumer_poll() at
  * regular intervals to serve queued callbacks.
  *
  * @remark Requires broker version 0.9.0 or later.
*)

type
  throttle_cb = procedure(rk: prd_kafka_t; broker_name: PAnsiChar; broker_id: Int32; throttle_time_ms: integer; opaque: Pointer); cdecl;

procedure rd_kafka_conf_set_throttle_cb(conf: prd_kafka_conf_t; cb: throttle_cb); cdecl;

(* *
  * @brief Set logger callback.
  *
  * The default is to print to stderr, but a syslog logger is also available,
  * see rd_kafka_log_print and rd_kafka_log_syslog for the builtin alternatives.
  * Alternatively the application may provide its own logger callback.
  * Or pass \p func as NULL to disable logging.
  *
  * This is the configuration alternative to the deprecated rd_kafka_set_logger()
*)

type
  log_cb = procedure(rk: prd_kafka_t; level: integer; fac: PAnsiChar; buf: PAnsiChar); cdecl;

procedure rd_kafka_conf_set_log_cb(conf: prd_kafka_conf_t; cb: log_cb); cdecl;

(* *
  * @brief Set statistics callback in provided conf object.
  *
  * The statistics callback is triggered from rd_kafka_poll() every
  * \c statistics.interval.ms (needs to be configured separately).
  * Function arguments:
  *   - \p rk - Kafka handle
  *   - \p json - String containing the statistics data in JSON format
  *   - \p json_len - Length of \p json string.
  *   - \p opaque - Application-provided opaque.
  *
  * If the application wishes to hold on to the \p json pointer and free
  * it at a later time it must return 1 from the \p stats_cb.
  * If the application returns 0 from the \p stats_cb then librdkafka
  * will immediately free the \p json pointer.
*)

type

  stats_cb = function(rk: prd_kafka_t; json: PAnsiChar; json_len: NativeUInt; opaque: Pointer): integer; cdecl;

procedure rd_kafka_conf_set_stats_cb(conf: prd_kafka_conf_t; cb: stats_cb); cdecl;

(* *
  * @brief Set socket callback.
  *
  * The socket callback is responsible for opening a socket
  * according to the supplied \p domain, \p type and \p protocol.
  * The socket shall be created with \c CLOEXEC set in a racefree fashion, if
  * possible.
  *
  * Default:
  *  - on linux: racefree CLOEXEC
  *  - others  : non-racefree CLOEXEC
*)

type
  socket_cb = function(domain: integer; &type: integer; protocol: integer; opaque: Pointer): integer; cdecl;
procedure rd_kafka_conf_set_socket_cb(conf: prd_kafka_conf_t; cb: socket_cb); cdecl;

{$IFNDEF MSWINDOWS}
(* *
  * @brief Set open callback.
  *
  * The open callback is responsible for opening the file specified by
  * pathname, flags and mode.
  * The file shall be opened with \c CLOEXEC set in a racefree fashion, if
  * possible.
  *
  * Default:
  *  - on linux: racefree CLOEXEC
  *  - others  : non-racefree CLOEXEC
*)

type
  open_cb = function(pathname: PAnsiChar; flags: integer; mode: mode_t; opaque: Pointer): integer; cdecl;

procedure rd_kafka_conf_set_open_cb(conf: prd_kafka_conf_t; cb: open_cb); cdecl;
{$ENDIF}

(* *
  * @brief Sets the application's opaque pointer that will be passed to callbacks
*)

procedure rd_kafka_conf_set_opaque(conf: prd_kafka_conf_t; opaque: Pointer); cdecl;

(* *
  * @brief Retrieves the opaque pointer previously set with rd_kafka_conf_set_opaque()
*)

procedure rd_kafka_opaque(rk: prd_kafka_t); cdecl;

(* *
  * Sets the default topic configuration to use for automatically
  * subscribed topics (e.g., through pattern-matched topics).
  * The topic config object is not usable after this call.
*)

procedure rd_kafka_conf_set_default_topic_conf(conf: prd_kafka_conf_t; tconf: prd_kafka_topic_conf_t); cdecl;

(* *
  * @brief Retrieve configuration value for property \p name.
  *
  * If \p dest is non-NULL the value will be written to \p dest with at
  * most \p dest_size.
  *
  * \p *dest_size is updated to the full length of the value, thus if
  * \p *dest_size initially is smaller than the full length the application
  * may reallocate \p dest to fit the returned \p *dest_size and try again.
  *
  * If \p dest is NULL only the full length of the value is returned.
  *
  * Returns \p RD_KAFKA_CONF_OK if the property name matched, else
  * \p RD_KAFKA_CONF_UNKNOWN.
*)

function rd_kafka_conf_get(conf: prd_kafka_conf_t; name: PAnsiChar; dest: PAnsiChar; dest_size: PNativeUInt): rd_kafka_conf_res_t; cdecl;

(* *
  * @brief Retrieve topic configuration value for property \p name.
  *
  * @sa rd_kafka_conf_get()
*)

function rd_kafka_topic_conf_get(conf: prd_kafka_topic_conf_t; name: PAnsiChar; dest: PAnsiChar; dest_size: PNativeUInt): rd_kafka_conf_res_t; cdecl;

(* *
  * @brief Dump the configuration properties and values of \p conf to an array
  *        with \ckey\c, \cvalue\c pairs.
  *
  * The number of entries in the array is returned in \p *cntp.
  *
  * The dump must be freed with `rd_kafka_conf_dump_free()`.
*)

type
  TAnsiCharArray = array [0 .. 0] of PAnsiChar;
  PAnsiCharArray = ^TAnsiCharArray;
function rd_kafka_conf_dump(conf: prd_kafka_conf_t; var cntp: NativeUInt): PAnsiCharArray; cdecl;

(* *
  * @brief Dump the topic configuration properties and values of \p conf
  *        to an array with \ckey\c, \cvalue\c pairs.
  *
  * The number of entries in the array is returned in \p *cntp.
  *
  * The dump must be freed with `rd_kafka_conf_dump_free()`.
*)

function rd_kafka_topic_conf_dump(conf: prd_kafka_conf_t; var cntp: NativeUInt): PAnsiCharArray; cdecl;

(* *
  * @brief Frees a configuration dump returned from `rd_kafka_conf_dump()` or
  *        `rd_kafka_topic_conf_dump().
*)

procedure rd_kafka_conf_dump_free(arr: PAnsiCharArray; cnt: NativeUInt); cdecl;

(* *
  * @brief Prints a table to \p fp of all supported configuration properties,
  *        their default values as well as a description.
*)


// procedure rd_kafka_conf_properties_show(fp: pFILE); cdecl;

(* *@} *)

(* *
  * @name Topic configuration
  * @{
  *
  * @brief Topic configuration property interface
  *
*)

(* *
  * @brief Create topic configuration object
  *
  * @sa Same semantics as for rd_kafka_conf_new().
*)

function rd_kafka_topic_conf_new: prd_kafka_topic_conf_t; cdecl;

(* *
  * @brief Creates a copy/duplicate of topic configuration object \p conf.
*)

function rd_kafka_topic_conf_dup(conf: prd_kafka_topic_conf_t): prd_kafka_topic_conf_t; cdecl;

(* *
  * @brief Destroys a topic conf object.
*)

procedure rd_kafka_topic_conf_destroy(topic_conf: prd_kafka_topic_conf_t); cdecl;

(* *
  * @brief Sets a single rd_kafka_topic_conf_t value by property name.
  *
  * \p topic_conf should have been previously set up
  * with `rd_kafka_topic_conf_new()`.
  *
  * @returns rd_kafka_conf_res_t to indicate success or failure.
*)

function rd_kafka_topic_conf_set(conf: prd_kafka_topic_conf_t; name: PAnsiChar; value: PAnsiChar; errstr: PAnsiChar; errstr_size: NativeUInt): rd_kafka_conf_res_t; cdecl;

(* *
  * @brief Sets the application's opaque pointer that will be passed to all topic
  * callbacks as the \c rkt_opaque argument.
*)

procedure rd_kafka_topic_conf_set_opaque(conf: prd_kafka_topic_conf_t; opaque: Pointer); cdecl;

(* *
  * @brief \b Producer: Set partitioner callback in provided topic conf object.
  *
  * The partitioner may be called in any thread at any time,
  * it may be called multiple times for the same message/key.
  *
  * Partitioner function constraints:
  *   - MUST NOT call any rd_kafka_*() functions except:
  *       rd_kafka_topic_partition_available()
  *   - MUST NOT block or execute for prolonged periods of time.
  *   - MUST return a value between 0 and partition_cnt-1, or the
  *     special \c RD_KAFKA_PARTITION_UA value if partitioning
  *     could not be performed.
*)

type
  partitioner = function(rkt: prd_kafka_topic_t; keydata: Pointer; keylen: NativeUInt; partition_cnt: Int32; rkt_opaque: Pointer; msg_opaque: Pointer): Int32; cdecl;

procedure rd_kafka_topic_conf_set_partitioner_cb(topic_conf: prd_kafka_topic_conf_t; p: partitioner); cdecl;

(* *
  * @brief Check if partition is available (has a leader broker).
  *
  * @returns 1 if the partition is available, else 0.
  *
  * @warning This function must only be called from inside a partitioner function
*)

function rd_kafka_topic_partition_available(rkt: prd_kafka_topic_t; partition: Int32): integer; cdecl;

(* ******************************************************************
  *           *
  * Partitioners provided by rdkafka                                *
  *           *
  ****************************************************************** *)

(* *
  * @brief Random partitioner.
  *
  * Will try not to return unavailable partitions.
  *
  * @returns a random partition between 0 and \p partition_cnt - 1.
  *
*)

function rd_kafka_msg_partitioner_random(rkt: prd_kafka_topic_t; key: Pointer; keylen: NativeUInt; partition_cnt: Int32; opaque: Pointer; msg_opaque: Pointer): Int32; cdecl;

(* *
  * @brief Consistent partitioner.
  *
  * Uses consistent hashing to map identical keys onto identical partitions.
  *
  * @returns a \crandom\c partition between 0 and \p partition_cnt - 1 based on
  *          the CRC value of the key
*)

function rd_kafka_msg_partitioner_consistent(rkt: prd_kafka_topic_t; key: Pointer; keylen: NativeUInt; partition_cnt: Int32; opaque: Pointer; msg_opaque: Pointer): Int32; cdecl;

(* *
  * @brief Consistent-Random partitioner.
  *
  * This is the default partitioner.
  * Uses consistent hashing to map identical keys onto identical partitions, and
  * messages without keys will be assigned via the random partitioner.
  *
  * @returns a \crandom\c partition between 0 and \p partition_cnt - 1 based on
  *          the CRC value of the key (if provided)
*)

function rd_kafka_msg_partitioner_consistent_random(rkt: prd_kafka_topic_t; key: Pointer; keylen: NativeUInt; partition_cnt: Int32; opaque: Pointer; msg_opaque: Pointer): Int32; cdecl;

(* *@} *)

(* *
  * @name Main Kafka and Topic object handles
  * @{
  *
  *
*)

(* *
  * @brief Creates a new Kafka handle and starts its operation according to the
  *        specified \p type (\p RD_KAFKA_CONSUMER or \p RD_KAFKA_PRODUCER).
  *
  * \p conf is an optional struct created with `rd_kafka_conf_new()` that will
  * be used instead of the default configuration.
  * The \p conf object is freed by this function on success and must not be used
  * or destroyed by the application sub-sequently.
  * See `rd_kafka_conf_set()` et.al for more information.
  *
  * \p errstr must be a pointer to memory of at least size \p errstr_size where
  * `rd_kafka_new()` may write a human readable error message in case the
  * creation of a new handle fails. In which case the function returns NULL.
  *
  * @remark \b RD_KAFKA_CONSUMER: When a new \p RD_KAFKA_CONSUMER
  *           rd_kafka_t handle is created it may either operate in the
  *           legacy simple consumer mode using the rd_kafka_consume_start()
  *           interface, or the High-level KafkaConsumer API.
  * @remark An application must only use one of these groups of APIs on a given
  *         rd_kafka_t RD_KAFKA_CONSUMER handle.

  *
  * @returns The Kafka handle on success or NULL on error (see \p errstr)
  *
  * @sa To destroy the Kafka handle, use rd_kafka_destroy().
*)

function rd_kafka_new(&type: rd_kafka_type_t; conf: prd_kafka_conf_t; errstr: PAnsiChar; errstr_size: NativeUInt): prd_kafka_t; cdecl;

(* *
  * @brief Destroy Kafka handle.
  *
  * @remark This is a blocking operation.
*)

procedure rd_kafka_destroy(rk: prd_kafka_t); cdecl;

(* *
  * @brief Returns Kafka handle name.
*)

function rd_kafka_name(rk: prd_kafka_t): PAnsiChar; cdecl;

(* *
  * @brief Returns this client's broker-assigned group member id
  *
  * @remark This currently requires the high-level KafkaConsumer
  *
  * @returns An allocated string containing the current broker-assigned group
  *          member id, or NULL if not available.
  *          The application must free the string with \p free() or
  *          rd_kafka_mem_free()
*)

function rd_kafka_memberid(rk: prd_kafka_t): PAnsiChar; cdecl;

(* *
  * @brief Creates a new topic handle for topic named \p topic.
  *
  * \p conf is an optional configuration for the topic created with
  * `rd_kafka_topic_conf_new()` that will be used instead of the default
  * topic configuration.
  * The \p conf object is freed by this function and must not be used or
  * destroyed by the application sub-sequently.
  * See `rd_kafka_topic_conf_set()` et.al for more information.
  *
  * Topic handles are refcounted internally and calling rd_kafka_topic_new()
  * again with the same topic name will return the previous topic handle
  * without updating the original handle's configuration.
  * Applications must eventually call rd_kafka_topic_destroy() for each
  * succesfull call to rd_kafka_topic_new() to clear up resources.
  *
  * @returns the new topic handle or NULL on error (use rd_kafka_errno2err()
  *          to convert system \p errno to an rd_kafka_resp_err_t error code.
  *
  * @sa rd_kafka_topic_destroy()
*)

function rd_kafka_topic_new(rk: prd_kafka_t; topic: PAnsiChar; conf: prd_kafka_topic_conf_t): prd_kafka_topic_t; cdecl;

(* *
  * @brief Destroy topic handle previously created with `rd_kafka_topic_new()`.
  * @remark MUST NOT be used for internally created topics (topic_new0())
*)

procedure rd_kafka_topic_destroy(rkt: prd_kafka_topic_t); cdecl;

(* *
  * @brief Returns the topic name.
*)

function rd_kafka_topic_name(rkt: prd_kafka_topic_t): PAnsiChar; cdecl;

(* *
  * @brief Get the \p rkt_opaque pointer that was set in the topic configuration.
*)

procedure rd_kafka_topic_opaque(rkt: prd_kafka_topic_t); cdecl;

(* *
  * @brief Unassigned partition.
  *
  * The unassigned partition is used by the producer API for messages
  * that should be partitioned using the configured or default partitioner.
*)
const
  RD_KAFKA_PARTITION_UA = Integer(-1);  // Was UInt32

  (* *
    * @brief Polls the provided kafka handle for events.
    *
    * Events will cause application provided callbacks to be called.
    *
    * The \p timeout_ms argument specifies the maximum amount of time
    * (in milliseconds) that the call will block waiting for events.
    * For non-blocking calls, provide 0 as \p timeout_ms.
    * To wait indefinately for an event, provide -1.
    *
    * @remark  An application should make sure to call poll() at regular
    *          intervals to serve any queued callbacks waiting to be called.
    *
    * Events:
    *   - delivery report callbacks  (if dr_cb/dr_msg_cb is configured) [producer]
    *   - error callbacks (rd_kafka_conf_set_error_cb()) [all]
    *   - stats callbacks (rd_kafka_conf_set_stats_cb()) [all]
    *   - throttle callbacks (rd_kafka_conf_set_throttle_cb()) [all]
    *
    * @returns the number of events served.
  *)

function rd_kafka_poll(rk: prd_kafka_t; timeout_ms: integer): integer; cdecl;

(* *
  * @brief Cancels the current callback dispatcher (rd_kafka_poll(),
  *        rd_kafka_consume_callback(), etc).
  *
  * A callback may use this to force an immediate return to the calling
  * code (caller of e.g. rd_kafka_poll()) without processing any further
  * events.
  *
  * @remark This function MUST ONLY be called from within a librdkafka callback.
*)

procedure rd_kafka_yield(rk: prd_kafka_t); cdecl;

(* *
  * @brief Pause producing or consumption for the provided list of partitions.
  *
  * Success or error is returned per-partition \p err in the \p partitions list.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR
*)

function rd_kafka_pause_partitions(rk: prd_kafka_t; partitions: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Resume producing consumption for the provided list of partitions.
  *
  * Success or error is returned per-partition \p err in the \p partitions list.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR
*)

function rd_kafka_resume_partitions(rk: prd_kafka_t; partitions: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Query broker for low (oldest/beginning) and high (newest/end) offsets
  *        for partition.
  *
  * Offsets are returned in \p *low and \p *high respectively.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success or an error code on failure.
*)

function rd_kafka_query_watermark_offsets(rk: prd_kafka_t; topic: PAnsiChar; partition: Int32; low: pInt64; high: pInt64; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Get last known low (oldest/beginning) and high (newest/end) offsets
  *        for partition.
  *
  * The low offset is updated periodically (if statistics.interval.ms is set)
  * while the high offset is updated on each fetched message set from the broker.
  *
  * If there is no cached offset (either low or high, or both) then
  * RD_KAFKA_OFFSET_INVALID will be returned for the respective offset.
  *
  * Offsets are returned in \p *low and \p *high respectively.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success or an error code on failure.
  *
  * @remark Shall only be used with an active consumer instance.
*)

function rd_kafka_get_watermark_offsets(rk: prd_kafka_t; topic: PAnsiChar; partition: Int32; low: pInt64; high: pInt64): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Free pointer returned by librdkafka
  *
  * This is typically an abstraction for the free(3) call and makes sure
  * the application can use the same memory allocator as librdkafka for
  * freeing pointers returned by librdkafka.
  *
  * In standard setups it is usually not necessary to use this interface
  * rather than the free(3) functione.
  *
  * @remark rd_kafka_mem_free() must only be used for pointers returned by APIs
  *         that explicitly mention using this function for freeing.
*)

procedure rd_kafka_mem_free(rk: prd_kafka_t; ptr: Pointer); cdecl;

(* *@} *)

(* *
  * @name Queue API
  * @{
  *
  * Message queues allows the application to re-route consumed messages
  * from multiple topic+partitions into one single queue point.
  * This queue point containing messages from a number of topic+partitions
  * may then be served by a single rd_kafka_consume*_queue() call,
  * rather than one call per topic+partition combination.
*)

(* *
  * @brief Create a new message queue.
  *
  * See rd_kafka_consume_start_queue(), rd_kafka_consume_queue(), et.al.
*)

function rd_kafka_queue_new(rk: prd_kafka_t): prd_kafka_queue_t; cdecl;

(* *
  * Destroy a queue, purging all of its enqueued messages.
*)

procedure rd_kafka_queue_destroy(rkqu: prd_kafka_queue_t); cdecl;

(* *
  * @returns a reference to the main librdkafka event queue.
  * This is the queue served by rd_kafka_poll().
  *
  * Use rd_kafka_queue_destroy() to loose the reference.
*)

function rd_kafka_queue_get_main(rk: prd_kafka_t): prd_kafka_queue_t; cdecl;

(* *
  * @returns a reference to the librdkafka consumer queue.
  * This is the queue served by rd_kafka_consumer_poll().
  *
  * Use rd_kafka_queue_destroy() to loose the reference.
  *
  * @remark rd_kafka_queue_destroy() MUST be called on this queue
  *         prior to calling rd_kafka_consumer_close().
*)

function rd_kafka_queue_get_consumer(rk: prd_kafka_t): prd_kafka_queue_t; cdecl;

(* *
  * @brief Forward/re-route queue \p src to \p dst.
  * If \p dst is \c NULL the forwarding is removed.
  *
  * The internal refcounts for both queues are increased.
*)

procedure rd_kafka_queue_forward(src: prd_kafka_queue_t; dst: prd_kafka_queue_t); cdecl;

(* *
  * @returns the current number of elements in queue.
*)

function rd_kafka_queue_length(rkqu: prd_kafka_queue_t): NativeUInt; cdecl;

(* *
  * @brief Enable IO event triggering for queue.
  *
  * To ease integration with IO based polling loops this API
  * allows an application to create a separate file-descriptor
  * that librdkafka will write \p payload (of size \p size) to
  * whenever a new element is enqueued on a previously empty queue.
  *
  * To remove event triggering call with \p fd = -1.
  *
  * librdkafka will maintain a copy of the \p payload.
  *
  * @remark When using forwarded queues the IO event must only be enabled
  *         on the final forwarded-to (destination) queue.
*)

procedure rd_kafka_queue_io_event_enable(rkqu: prd_kafka_queue_t; fd: integer; payload: Pointer; size: NativeUInt); cdecl;

(* *@} *)

(* *
  *
  * @name Simple Consumer API (legacy)
  * @{
  *
*)
const

  RD_KAFKA_OFFSET_BEGINNING = -2; (* *< Start consuming from beginning of kafka partition queue:oldest msg *)
  RD_KAFKA_OFFSET_END = -1; (* *< Start consuming from end of kafka partition queue:next msg *)
  RD_KAFKA_OFFSET_STORED = -1000; (* *< Start consuming from offset retrieved from offset store *)
  RD_KAFKA_OFFSET_INVALID = -1001; (* *< Invalid offset *)

  (* * @cond NO_DOC *)
  RD_KAFKA_OFFSET_TAIL_BASE = -2000; (* internal: do not use *)
  (* * @endcond *)

  (* *
    * @brief Start consuming \p CNT messages from topic's current end offset.
    *
    * That is, if current end offset is 12345 and \p CNT is 200, it will start
    * consuming from offset \c 12345-200 = \c 12145. *)

function RD_KAFKA_OFFSET_TAIL(cnt: integer): integer; inline;

(* *
  * @brief Start consuming messages for topic \p rkt and \p partition
  * at offset \p offset which may either be an absolute \c (0..N)
  * or one of the logical offsets:
  *  - RD_KAFKA_OFFSET_BEGINNING
  *  - RD_KAFKA_OFFSET_END
  *  - RD_KAFKA_OFFSET_STORED
  *  - RD_KAFKA_OFFSET_TAIL
  *
  * rdkafka will attempt to keep \c queued.min.messages (config property)
  * messages in the local queue by repeatedly fetching batches of messages
  * from the broker until the threshold is reached.
  *
  * The application shall use one of the `rd_kafka_consume*()` functions
  * to consume messages from the local queue, each kafka message being
  * represented as a `rd_kafka_message_t *` object.
  *
  * `rd_kafka_consume_start()` must not be called multiple times for the same
  * topic and partition without stopping consumption first with
  * `rd_kafka_consume_stop()`.
  *
  * @returns 0 on success or -1 on error in which case errno is set accordingly:
  *  - EBUSY    - Conflicts with an existing or previous subscription
  *               (RD_KAFKA_RESP_ERR__CONFLICT)
  *  - EINVAL   - Invalid offset, or incomplete configuration (lacking group.id)
  *               (RD_KAFKA_RESP_ERR__INVALID_ARG)
  *  - ESRCH    - requested \p partition is invalid.
  *               (RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION)
  *  - ENOENT   - topic is unknown in the Kafka cluster.
  *               (RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC)
  *
  * Use `rd_kafka_errno2err()` to convert sytem \c errno to `rd_kafka_resp_err_t`
*)

(* *
  * @brief Same as rd_kafka_consume_start() but re-routes incoming messages to
  * the provided queue \p rkqu (which must have been previously allocated
  * with `rd_kafka_queue_new()`.
  *
  * The application must use one of the `rd_kafka_consume_*_queue()` functions
  * to receive fetched messages.
  *
  * `rd_kafka_consume_start_queue()` must not be called multiple times for the
  * same topic and partition without stopping consumption first with
  * `rd_kafka_consume_stop()`.
  * `rd_kafka_consume_start()` and `rd_kafka_consume_start_queue()` must not
  * be combined for the same topic and partition.
*)

function rd_kafka_consume_start_queue(rkt: prd_kafka_topic_t; partition: Int32; offset: Int64; rkqu: prd_kafka_queue_t): integer; cdecl;

(* *
  * @brief Stop consuming messages for topic \p rkt and \p partition, purging
  * all messages currently in the local queue.
  *
  * NOTE: To enforce synchronisation this call will block until the internal
  *       fetcher has terminated and offsets are committed to configured
  *       storage method.
  *
  * The application needs to be stop all consumers before calling
  * `rd_kafka_destroy()` on the main object handle.
  *
  * @returns 0 on success or -1 on error (see `errno`).
*)

function rd_kafka_consume_stop(rkt: prd_kafka_topic_t; partition: Int32): integer; cdecl;

(* *
  * @brief Seek consumer for topic+partition to \p offset which is either an
  *        absolute or logical offset.
  *
  * If \p timeout_ms is not 0 the call will wait this long for the
  * seek to be performed. If the timeout is reached the internal state
  * will be unknown and this function returns `RD_KAFKA_RESP_ERR__TIMED_OUT`.
  * If \p timeout_ms is 0 it will initiate the seek but return
  * immediately without any error reporting (e.g., async).
  *
  * This call triggers a fetch queue barrier flush.
  *
  * @returns `RD_KAFKA_RESP_ERR__NO_ERROR` on success else an error code.
*)

function rd_kafka_seek(rkt: prd_kafka_topic_t; partition: Int32; offset: Int64; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Consume a single message from topic \p rkt and \p partition
  *
  * \p timeout_ms is maximum amount of time to wait for a message to be received.
  * Consumer must have been previously started with `rd_kafka_consume_start()`.
  *
  * Returns a message object on success or \c NULL on error.
  * The message object must be destroyed with `rd_kafka_message_destroy()`
  * when the application is done with it.
  *
  * Errors (when returning NULL):
  *  - ETIMEDOUT - \p timeout_ms was reached with no new messages fetched.
  *  - ENOENT    - \p rkt + \p partition is unknown.
  *                 (no prior `rd_kafka_consume_start()` call)
  *
  * NOTE: The returned message's \c ..->err must be checked for errors.
  * NOTE: \c ..->err \c == \c RD_KAFKA_RESP_ERR__PARTITION_EOF signals that the
  0*       end of the partition has been reached, which should typically not be
  *       considered an error. The application should handle this case
  *       (e.g., ignore).
*)

function rd_kafka_consume(rkt: prd_kafka_topic_t; partition: Int32; timeout_ms: integer): prd_kafka_message_t; cdecl;

(* *
  * @brief Consume up to \p rkmessages_size from topic \p rkt and \p partition
  *        putting a pointer to each message in the application provided
  *        array \p rkmessages (of size \p rkmessages_size entries).
  *
  * `rd_kafka_consume_batch()` provides higher throughput performance
  * than `rd_kafka_consume()`.
  *
  * \p timeout_ms is the maximum amount of time to wait for all of
  * \p rkmessages_size messages to be put into \p rkmessages.
  * If no messages were available within the timeout period this function
  * returns 0 and \p rkmessages remains untouched.
  * This differs somewhat from `rd_kafka_consume()`.
  *
  * The message objects must be destroyed with `rd_kafka_message_destroy()`
  * when the application is done with it.
  *
  * @returns the number of rkmessages added in \p rkmessages,
  * or -1 on error (same error codes as for `rd_kafka_consume()`.
  *
  * @sa rd_kafka_consume()
*)

function rd_kafka_consume_batch(rkt: prd_kafka_topic_t; partition: Int32; timeout_ms: integer; var rkmessages: rd_kafka_message_t; rkmessages_size: NativeUInt): NativeInt; cdecl;

(* *
  * @brief Consumes messages from topic \p rkt and \p partition, calling
  * the provided callback for each consumed messsage.
  *
  * `rd_kafka_consume_callback()` provides higher throughput performance
  * than both `rd_kafka_consume()` and `rd_kafka_consume_batch()`.
  *
  * \p timeout_ms is the maximum amount of time to wait for one or more messages
  * to arrive.
  *
  * The provided \p consume_cb function is called for each message,
  * the application \b MUST \b NOT call `rd_kafka_message_destroy()` on the
  * provided \p rkmessage.
  *
  * The \p opaque argument is passed to the 'consume_cb' as \p opaque.
  *
  * @returns the number of messages processed or -1 on error.
  *
  * @sa rd_kafka_consume()
*)

type
  consume_cb = procedure(rkmessage: prd_kafka_message_t; opaque: Pointer); cdecl;
function rd_kafka_consume_callback(rkt: prd_kafka_topic_t; partition: Int32; timeout_ms: integer; cb: consume_cb; opaque: Pointer): integer; cdecl;

(* *
  * @name Simple Consumer API (legacy): Queue consumers
  * @{
  *
  * The following `..._queue()` functions are analogue to the functions above
  * but reads messages from the provided queue \p rkqu instead.
  * \p rkqu must have been previously created with `rd_kafka_queue_new()`
  * and the topic consumer must have been started with
  * `rd_kafka_consume_start_queue()` utilising the the same queue.
*)

(* *
  * @brief Consume from queue
  *
  * @sa rd_kafka_consume()
*)

function rd_kafka_consume_queue(rkqu: prd_kafka_queue_t; timeout_ms: integer): prd_kafka_message_t; cdecl;

(* *
  * @brief Consume batch of messages from queue
  *
  * @sa rd_kafka_consume_batch()
*)

function rd_kafka_consume_batch_queue(rkqu: prd_kafka_queue_t; timeout_ms: integer; var rkmessages: rd_kafka_message_t; rkmessages_size: NativeUInt): NativeInt; cdecl;

(* *
  * @brief Consume multiple messages from queue with callback
  *
  * @sa rd_kafka_consume_callback()
*)

type

  consume_queue_cb = procedure(rkmessage: prd_kafka_message_t; opaque: Pointer); cdecl;

function rd_kafka_consume_callback_queue(rkqu: prd_kafka_queue_t; timeout_ms: integer; cb: consume_queue_cb; opaque: Pointer): integer; cdecl;

(* *@} *)

(* *
  * @name Simple Consumer API (legacy): Topic+partition offset store.
  * @{
  *
  * If \c auto.commit.enable is true the offset is stored automatically prior to
  * returning of the message(s) in each of the rd_kafka_consume*() functions
  * above.
*)

(* *
  * @brief Store offset \p offset for topic \p rkt partition \p partition.
  *
  * The offset will be committed (written) to the offset store according
  * to \c `auto.commit.interval.ms`.
  *
  * @remark \c `auto.commit.enable` must be set to "false" when using this API.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success or an error code on error.
*)

function rd_kafka_offset_store(rkt: prd_kafka_topic_t; partition: Int32; offset: Int64): rd_kafka_resp_err_t; cdecl;
(* *@} *)

(* *
  * @name KafkaConsumer (C)
  * @{
  * @brief High-level KafkaConsumer C API
  *
  *
  *
*)

(* *
  * @brief Subscribe to topic set using balanced consumer groups.
  *
  * Wildcard (regex) topics are supported by the librdkafka assignor:
  * any topic name in the \p topics list that is prefixed with \c \c^\c will
  * be regex-matched to the full list of topics in the cluster and matching
  * topics will be added to the subscription list.
*)

function rd_kafka_subscribe(rk: prd_kafka_t; topics: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Unsubscribe from the current subscription set.
*)

function rd_kafka_unsubscribe(rk: prd_kafka_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Returns the current topic subscription
  *
  * @returns An error code on failure, otherwise \p topic is updated
  *          to point to a newly allocated topic list (possibly empty).
  *
  * @remark The application is responsible for calling
  *         rd_kafka_topic_partition_list_destroy on the returned list.
*)

function rd_kafka_subscription(rk: prd_kafka_t; var topics: rd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Poll the consumer for messages or events.
  *
  * Will block for at most \p timeout_ms milliseconds.
  *
  * @remark  An application should make sure to call consumer_poll() at regular
  *          intervals, even if no messages are expected, to serve any
  *          queued callbacks waiting to be called. This is especially
  *          important when a rebalance_cb has been registered as it needs
  *          to be called and handled properly to synchronize internal
  *          consumer state.
  *
  * @returns A message object which is a proper message if \p ->err is
  *          RD_KAFKA_RESP_ERR_NO_ERROR, or an event or error for any other
  *          value.
  *
  * @sa rd_kafka_message_t
*)

function rd_kafka_consumer_poll(rk: prd_kafka_t; timeout_ms: integer): prd_kafka_message_t; cdecl;

(* *
  * @brief Close down the KafkaConsumer.
  *
  * @remark This call will block until the consumer has revoked its assignment,
  *         calling the \c rebalance_cb if it is configured, committed offsets
  *         to broker, and left the consumer group.
  *         The maximum blocking time is roughly limited to session.timeout.ms.
  *
  * @returns An error code indicating if the consumer close was succesful
  *          or not.
  *
  * @remark The application still needs to call rd_kafka_destroy() after
  *         this call finishes to clean up the underlying handle resources.
  *
*)

function rd_kafka_consumer_close(rk: prd_kafka_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Atomic assignment of partitions to consume.
  *
  * The new \p partitions will replace the existing assignment.
  *
  * When used from a rebalance callback the application shall pass the
  * partition list passed to the callback (or a copy of it) (even if the list
  * is empty) rather than NULL to maintain internal join state.

  * A zero-length \p partitions will treat the partitions as a valid,
  * albeit empty, assignment, and maintain internal state, while a \c NULL
  * value for \p partitions will reset and clear the internal state.
*)

function rd_kafka_assign(rk: prd_kafka_t; partitions: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Returns the current partition assignment
  *
  * @returns An error code on failure, otherwise \p partitions is updated
  *          to point to a newly allocated partition list (possibly empty).
  *
  * @remark The application is responsible for calling
  *         rd_kafka_topic_partition_list_destroy on the returned list.
*)

function rd_kafka_assignment(rk: prd_kafka_t; var partitions: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Commit offsets on broker for the provided list of partitions.
  *
  * \p offsets should contain \c topic, \c partition, \c offset and possibly
  * \c metadata.
  * If \p offsets is NULL the current partition assignment will be used instead.
  *
  * If \p async is false this operation will block until the broker offset commit
  * is done, returning the resulting success or error code.
  *
  * If a rd_kafka_conf_set_offset_commit_cb() offset commit callback has been
  * configured:
  *  * if async: callback will be enqueued for a future call to rd_kafka_poll().
  *  * if !async: callback will be called from rd_kafka_commit()
*)

function rd_kafka_commit(rk: prd_kafka_t; offsets: prd_kafka_topic_partition_list_t; async: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Commit message's offset on broker for the message's partition.
  *
  * @sa rd_kafka_commit
*)

function rd_kafka_commit_message(rk: prd_kafka_t; rkmessage: prd_kafka_message_t; async: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Commit offsets on broker for the provided list of partitions.
  *
  * See rd_kafka_commit for \p offsets semantics.
  *
  * The result of the offset commit will be posted on the provided \p rkqu queue.
  *
  * If the application uses one of the poll APIs (rd_kafka_poll(),
  * rd_kafka_consumer_poll(), rd_kafka_queue_poll(), ..) to serve the queue
  * the \p cb callback is required. \p opaque is passed to the callback.
  *
  * If using the event API the callback is ignored and the offset commit result
  * will be returned as an RD_KAFKA_EVENT_COMMIT event. The \p opaque
  * value will be available with rd_kafka_event_opaque()
  *
  * If \p rkqu is NULL a temporary queue will be created and the callback will
  * be served by this call.
  *
  * @sa rd_kafka_commit()
  * @sa rd_kafka_conf_set_offset_commit_cb()
*)

type
  commit_queue_cb = procedure(rk: prd_kafka_t; err: rd_kafka_resp_err_t; offsets: prd_kafka_topic_partition_list_t; opaque: Pointer); cdecl;

function rd_kafka_commit_queue(rk: prd_kafka_t; offsets: prd_kafka_topic_partition_list_t; rkqu: prd_kafka_queue_t; cb: commit_queue_cb; opaque: Pointer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Retrieve committed offsets for topics+partitions.
  *
  * The \p offset field of each requested partition will either be set to
  * stored offset or to RD_KAFKA_OFFSET_INVALID in case there was no stored
  * offset for that partition.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success in which case the
  *          \p offset or \p err field of each \p partitions' element is filled
  *          in with the stored offset, or a partition specific error.
  *          Else returns an error code.
*)

function rd_kafka_committed(rk: prd_kafka_t; partitions: prd_kafka_topic_partition_list_t; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Retrieve current positions (offsets) for topics+partitions.
  *
  * The \p offset field of each requested partition will be set to the offset
  * of the last consumed message + 1, or RD_KAFKA_OFFSET_INVALID in case there was
  * no previous message.
  *
  * @returns RD_KAFKA_RESP_ERR_NO_ERROR on success in which case the
  *          \p offset or \p err field of each \p partitions' element is filled
  *          in with the stored offset, or a partition specific error.
  *          Else returns an error code.
*)

function rd_kafka_position(rk: prd_kafka_t; partitions: prd_kafka_topic_partition_list_t): rd_kafka_resp_err_t; cdecl;

(* *@} *)

(* *
  * @name Producer API
  * @{
  *
  *
*)

(* *
  * @brief Producer message flags
*)
const
  RD_KAFKA_MSG_F_FREE = $1; (* *< Delegate freeing of payload to rdkafka. *)
  RD_KAFKA_MSG_F_COPY = $2; (* *< rdkafka will make a copy of the payload. *)
  RD_KAFKA_MSG_F_BLOCK = $4; (* *< Block produce*() on message queue full.
    *   WARNING: If a delivery report callback
    *            is used the application MUST
    *            call rd_kafka_poll() (or equiv.)
    *            to make sure delivered messages
    *            are drained from the internal
    *            delivery report queue.
    *            Failure to do so will result
    *            in indefinately blocking on
    *            the produce() call when the
    *            message queue is full.
  *)

  (* *
    * @brief Produce and send a single message to broker.
    *
    * \p rkt is the target topic which must have been previously created with
    * `rd_kafka_topic_new()`.
    *
    * `rd_kafka_produce()` is an asynch non-blocking API.
    *
    * \p partition is the target partition, either:
    *   - RD_KAFKA_PARTITION_UA (unassigned) for
    *     automatic partitioning using the topic's partitioner function, or
    *   - a fixed partition (0..N)
    *
    * \p msgflags is zero or more of the following flags OR:ed together:
    *    RD_KAFKA_MSG_F_BLOCK - block \p produce*() call if
    *                           \p queue.buffering.max.messages or
    *                           \p queue.buffering.max.kbytes are exceeded.
    *                           Messages are considered in-queue from the point they
    *                           are accepted by produce() until their corresponding
    *                           delivery report callback/event returns.
    *                           It is thus a requirement to call
    *                           rd_kafka_poll() (or equiv.) from a separate
    *                           thread when F_BLOCK is used.
    *                           See WARNING on \c RD_KAFKA_MSG_F_BLOCK above.
    *
    *    RD_KAFKA_MSG_F_FREE - rdkafka will free(3) \p payload when it is done
    *                          with it.
    *    RD_KAFKA_MSG_F_COPY - the \p payload data will be copied and the
    *                          \p payload pointer will not be used by rdkafka
    *                          after the call returns.
    *
    *    .._F_FREE and .._F_COPY are mutually exclusive.
    *
    *    If the function returns -1 and RD_KAFKA_MSG_F_FREE was specified, then
    *    the memory associated with the payload is still the caller's
    *    responsibility.
    *
    * \p payload is the message payload of size \p len bytes.
    *
    * \p key is an optional message key of size \p keylen bytes, if non-NULL it
    * will be passed to the topic partitioner as well as be sent with the
    * message to the broker and passed on to the consumer.
    *
    * \p msg_opaque is an optional application-provided per-message opaque
    * pointer that will provided in the delivery report callback (`dr_cb`) for
    * referencing this message.
    *
    * Returns 0 on success or -1 on error in which case errno is set accordingly:
    *  - ENOBUFS  - maximum number of outstanding messages has been reached:
    *               "queue.buffering.max.messages"
    *               (RD_KAFKA_RESP_ERR__QUEUE_FULL)
    *  - EMSGSIZE - message is larger than configured max size:
    *               "messages.max.bytes".
    *               (RD_KAFKA_RESP_ERR_MSG_SIZE_TOO_LARGE)
    *  - ESRCH    - requested \p partition is unknown in the Kafka cluster.
    *               (RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION)
    *  - ENOENT   - topic is unknown in the Kafka cluster.
    *               (RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC)
    *
    * @sa Use rd_kafka_errno2err() to convert `errno` to rdkafka error code.
  *)

Function rd_kafka_produce(rkt : prd_kafka_topic_t; partition : int32; msgflags : Integer; payload : Pointer; len : NativeUInt; key : Pointer; keylen : NativeUInt; msg_opaque : Pointer) : Integer; cdecl; // DB

  (* *
    * @brief Produce multiple messages.
    *
    * If partition is RD_KAFKA_PARTITION_UA the configured partitioner will
    * be run for each message (slower), otherwise the messages will be enqueued
    * to the specified partition directly (faster).
    *
    * The messages are provided in the array \p rkmessages of count \p message_cnt
    * elements.
    * The \p partition and \p msgflags are used for all provided messages.
    *
    * Honoured \p rkmessages[] fields are:
    *  - payload,len    Message payload and length
    *  - key,key_len    Optional message key
    *  - _private       Message opaque pointer (msg_opaque)
    *  - err            Will be set according to success or failure.
    *                   Application only needs to check for errors if
    *                   return value != \p message_cnt.
    *
    * @returns the number of messages succesfully enqueued for producing.
  *)


function rd_kafka_produce_batch(rkt: prd_kafka_topic_t; partition: Int32; msgflags: integer; rkmessages: prd_kafka_message_t; message_cnt: integer): integer; cdecl;

(* *
  * @brief Wait until all outstanding produce requests, et.al, are completed.
  *        This should typically be done prior to destroying a producer instance
  *        to make sure all queued and in-flight produce requests are completed
  *        before terminating.
  *
  * @remark This function will call rd_kafka_poll() and thus trigger callbacks.
  *
  * @returns RD_KAFKA_RESP_ERR__TIMED_OUT if \p timeout_ms was reached before all
  *          outstanding requests were completed, else RD_KAFKA_RESP_ERR_NO_ERROR
*)

function rd_kafka_flush(rk: prd_kafka_t; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *@} *)

(* *
  * @name Metadata API
  * @{
  *
  *
*)

(* *
  * @brief Broker information
*)
type
  rd_kafka_metadata_broker = record
    id: Int32; (* *< Broker Id *)
    host: PAnsiChar; (* *< Broker hostname *)
    port: integer; (* *< Broker listening port *)
  end;

  rd_kafka_metadata_broker_t = rd_kafka_metadata_broker;
  prd_kafka_metadata_broker_t = ^rd_kafka_metadata_broker_t;
  prd_kafka_metadata_broker = ^rd_kafka_metadata_broker;

  (* *
    * @brief Partition information
  *)
  rd_kafka_metadata_partition = record
    id: Int32; (* *< Partition Id *)
    err: rd_kafka_resp_err_t; (* *< Partition error reported by broker *)
    leader: Int32; (* *< Leader broker *)
    replica_cnt: integer; (* *< Number of brokers in \p replicas *)
    replicas: ^Int32; (* *< Replica brokers *)
    isr_cnt: integer; (* *< Number of ISR brokers in \p isrs *)
    isrs: ^Int32; (* *< In-Sync-Replica brokers *)
  end;

  rd_kafka_metadata_partition_t = rd_kafka_metadata_partition;
  prd_kafka_metadata_partition_t = ^rd_kafka_metadata_partition_t;
  prd_kafka_metadata_partition = ^rd_kafka_metadata_partition;

  (* *
    * @brief Topic information
  *)
  rd_kafka_metadata_topic = record
    topic: PAnsiChar; (* *< Topic name *)
    partition_cnt: integer; (* *< Number of partitions in \p partitions *)
    partitions: prd_kafka_metadata_partition; (* *< Partitions *)
    err: rd_kafka_resp_err_t; (* *< Topic error reported by broker *)
  end;

  rd_kafka_metadata_topic_t = rd_kafka_metadata_topic;
  prd_kafka_metadata_topic_t = ^rd_kafka_metadata_topic_t;
  prd_kafka_metadata_topic = ^rd_kafka_metadata_topic;

  (* *
    * @brief Metadata container
  *)
  rd_kafka_metadata_t = record
    broker_cnt: integer; (* *< Number of brokers in \p brokers *)
    brokers: prd_kafka_metadata_broker; (* *< Brokers *)

    topic_cnt: integer; (* *< Number of topics in \p topics *)
    topics: prd_kafka_metadata_topic; (* *< Topics *)

    orig_broker_id: Int32; (* *< Broker originating this metadata *)
    orig_broker_name: PAnsiChar; (* *< Name of originating broker *)
  end;

  prd_kafka_metadata_t = ^rd_kafka_metadata_t;
  prd_kafka_metadata = ^rd_kafka_metadata_t;

  (* *
    * @brief Request Metadata from broker.
    *
    * Parameters:
    *  - \p all_topics  if non-zero: request info about all topics in cluster,
    *                   if zero: only request info about locally known topics.
    *  - \p only_rkt    only request info about this topic
    *  - \p metadatap   pointer to hold metadata result.
    *                   The \p *metadatap pointer must be released
    *                   with rd_kafka_metadata_destroy().
    *  - \p timeout_ms  maximum response time before failing.
    *
    * Returns RD_KAFKA_RESP_ERR_NO_ERROR on success (in which case *metadatap)
    * will be set, else RD_KAFKA_RESP_ERR__TIMED_OUT on timeout or
    * other error code on error.
  *)

function rd_kafka_metadata(rk: prd_kafka_t; all_topics: integer; only_rkt: prd_kafka_topic_t; var metadatap: prd_kafka_metadata; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Release metadata memory.
*)

procedure rd_kafka_metadata_destroy(metadata: prd_kafka_metadata); cdecl;

(* *@} *)

(* *
  * @name Client group information
  * @{
  *
  *
*)

(* *
  * @brief Group member information
  *
  * For more information on \p member_metadata format, see
  * https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-GroupMembershipAPI
  *
*)
type
  rd_kafka_group_member_info = record
    member_id: PAnsiChar; (* *< Member id (generated by broker) *)
    client_id: PAnsiChar; (* *< Client's \p client.id *)
    client_host: PAnsiChar; (* *< Client's hostname *)
    member_metadata: Pointer; (* *< Member metadata (binary),
      *   format depends on \p protocol_type. *)
    member_metadata_size: integer; (* *< Member metadata size in bytes *)
    member_assignment: Pointer; (* *< Member assignment (binary),
      *    format depends on \p protocol_type. *)
    member_assignment_size: integer; (* *< Member assignment size in bytes *)
  end;

  prd_kafka_group_member_info = ^rd_kafka_group_member_info;
  (* *
    * @brief Group information
  *)

  rd_kafka_group_info = record
    broker: rd_kafka_metadata_broker; (* *< Originating broker info *)
    group: PAnsiChar; (* *< Group name *)
    err: rd_kafka_resp_err_t; (* *< Broker-originated error *)
    state: PAnsiChar; (* *< Group state *)
    protocol_type: PAnsiChar; (* *< Group protocol type *)
    protocol: PAnsiChar; (* *< Group protocol *)
    members: prd_kafka_group_member_info; (* *< Group members *)
    member_cnt: integer; (* *< Group member count *)
  end;

  prd_kafka_group_info = ^rd_kafka_group_info;
  (* *
    * @brief List of groups
    *
    * @sa rd_kafka_group_list_destroy() to release list memory.
  *)

  rd_kafka_group_list = record
    groups: prd_kafka_group_info; (* *< Groups *)
    group_cnt: integer; (* *< Group count *)
  end;

  prd_kafka_group_list = ^rd_kafka_group_list;

  (* *
    * @brief List and describe client groups in cluster.
    *
    * \p group is an optional group name to describe, otherwise (\p NULL) all
    * groups are returned.
    *
    * \p timeout_ms is the (approximate) maximum time to wait for response
    * from brokers and must be a positive value.
    *
    * @returns \p RD_KAFKA_RESP_ERR__NO_ERROR on success and \p grplistp is
    *           updated to point to a newly allocated list of groups.
    *           Else returns an error code on failure and \p grplistp remains
    *           untouched.
    *
    * @sa Use rd_kafka_group_list_destroy() to release list memory.
  *)

function rd_kafka_list_groups(rk: prd_kafka_t; group: PAnsiChar; var grplistp: prd_kafka_group_list; timeout_ms: integer): rd_kafka_resp_err_t; cdecl;

(* *
  * @brief Release list memory
*)

procedure rd_kafka_group_list_destroy(grplist: prd_kafka_group_list); cdecl;

(* *@} *)

(* *
  * @name Miscellaneous APIs
  * @{
  *
*)

(* *
  * @brief Adds one or more brokers to the kafka handle's list of initial
  *        bootstrap brokers.
  *
  * Additional brokers will be discovered automatically as soon as rdkafka
  * connects to a broker by querying the broker metadata.
  *
  * If a broker name resolves to multiple addresses (and possibly
  * address families) all will be used for connection attempts in
  * round-robin fashion.
  *
  * \p brokerlist is a ,-separated list of brokers in the format:
  *   \c \<broker1\>,\<broker2\>,..
  * Where each broker is in either the host or URL based format:
  *   \c \<host\>[:\<port\>]
  *   \c \<proto\>://\<host\>[:port]
  * \c \<proto\> is either \c PLAINTEXT, \c SSL, \c SASL, \c SASL_PLAINTEXT
  * The two formats can be mixed but ultimately the value of the
  * `security.protocol` config property decides what brokers are allowed.
  *
  * Example:
  *    brokerlist = "broker1:10000,broker2"
  *    brokerlist = "SSL://broker3:9000,ssl://broker2"
  *
  * @returns the number of brokers successfully added.
  *
  * @remark Brokers may also be defined with the \c metadata.broker.list or
  *         \c bootstrap.servers configuration property (preferred method).
*)

function rd_kafka_brokers_add(rk: prd_kafka_t; brokerlist: PAnsiChar): integer; cdecl;

(* *
  * @brief Set logger function.
  *
  * The default is to print to stderr, but a syslog logger is also available,
  * see rd_kafka_log_(print|syslog) for the builtin alternatives.
  * Alternatively the application may provide its own logger callback.
  * Or pass 'func' as NULL to disable logging.
  *
  * @deprecated Use rd_kafka_conf_set_log_cb()
  *
  * @remark \p rk may be passed as NULL in the callback.
*)

type
  logger_func = procedure(rk: prd_kafka_t; level: integer; fac: PAnsiChar; buf: PAnsiChar); cdecl;

procedure rd_kafka_set_logger(rk: prd_kafka_t; func: logger_func); cdecl;

(* *
  * @brief Specifies the maximum logging level produced by
  *        internal kafka logging and debugging.
  *
  * If the \p \cdebug\c configuration property is set the level is automatically
  * adjusted to \c LOG_DEBUG (7).
*)

procedure rd_kafka_set_log_level(rk: prd_kafka_t; level: integer); cdecl;

(* *
  * @brief Builtin (default) log sink: print to stderr
*)

procedure rd_kafka_log_print(rk: prd_kafka_t; level: integer; fac: PAnsiChar; buf: PAnsiChar); cdecl;

(* *
  * @brief Builtin log sink: print to syslog.
*)

procedure rd_kafka_log_syslog(rk: prd_kafka_t; level: integer; fac: PAnsiChar; buf: PAnsiChar); cdecl;

(* *
  * @brief Returns the current out queue length.
  *
  * The out queue contains messages waiting to be sent to, or acknowledged by,
  * the broker.
  *
  * An application should wait for this queue to reach zero before terminating
  * to make sure outstanding requests (such as offset commits) are fully
  * processed.
  *
  * @returns number of messages in the out queue.
*)

function rd_kafka_outq_len(rk: prd_kafka_t): integer; cdecl;

(* *
  * @brief Dumps rdkafka's internal state for handle \p rk to stream \p fp
  *
  * This is only useful for debugging rdkafka, showing state and statistics
  * for brokers, topics, partitions, etc.
*)


// procedure rd_kafka_dump(fp: pFILE;  rk: prd_kafka_t); cdecl;

(* *
  * @brief Retrieve the current number of threads in use by librdkafka.
  *
  * Used by regression tests.
*)

function rd_kafka_thread_cnt: integer; cdecl;

(* *
  * @brief Wait for all rd_kafka_t objects to be destroyed.
  *
  * Returns 0 if all kafka objects are now destroyed, or -1 if the
  * timeout was reached.
  * Since `rd_kafka_destroy()` is an asynch operation the
  * `rd_kafka_wait_destroyed()` function can be used for applications where
  * a clean shutdown is required.
*)

function rd_kafka_wait_destroyed(timeout_ms: integer): integer; cdecl;

(* *@} *)

(* *
  * @name Experimental APIs
  * @{
*)

(* *
  * @brief Redirect the main (rd_kafka_poll()) queue to the KafkaConsumer's
  *        queue (rd_kafka_consumer_poll()).
  *
  * @warning It is not permitted to call rd_kafka_poll() after directing the
  *          main queue with rd_kafka_poll_set_consumer().
*)

function rd_kafka_poll_set_consumer(rk: prd_kafka_t): rd_kafka_resp_err_t; cdecl;

(* *@} *)

(* *
  * @name Event interface
  *
  * @brief The event API provides an alternative pollable non-callback interface
  *        to librdkafka's message and event queues.
  *
  * @{
*)

(* *
  * @brief Event types
*)
type
  rd_kafka_event_type_t = integer;

const
  RD_KAFKA_EVENT_NONE = $0;
  RD_KAFKA_EVENT_DR = $1; (* *< Producer Delivery report batch *)
  RD_KAFKA_EVENT_FETCH = $2; (* *< Fetched message (consumer) *)
  RD_KAFKA_EVENT_LOG_ = $4; (* *< Log message *)
  RD_KAFKA_EVENT_ERROR_ = $8; (* *< Error *)
  RD_KAFKA_EVENT_REBALANCE = $10; (* *< Group rebalance (consumer) *)
  RD_KAFKA_EVENT_OFFSET_COMMIT = $20; (* *< Offset commit result *)

type

  // rd_kafka_event_t = rd_kafka_op_s;
  prd_kafka_event_t = Pointer;

  (* *
    * @returns the event type for the given event.
    *
    * @remark As a convenience it is okay to pass \p rkev as NULL in which case
    *         RD_KAFKA_EVENT_NONE is returned.
  *)

function rd_kafka_event_type(rkev: prd_kafka_event_t): rd_kafka_event_type_t; cdecl;

(* *
  * @returns the event type's name for the given event.
  *
  * @remark As a convenience it is okay to pass \p rkev as NULL in which case
  *         the name for RD_KAFKA_EVENT_NONE is returned.
*)

function rd_kafka_event_name(rkev: prd_kafka_event_t): PAnsiChar; cdecl;

(* *
  * @brief Destroy an event.
  *
  * @remark Any references to this event, such as extracted messages,
  *         will not be usable after this call.
  *
  * @remark As a convenience it is okay to pass \p rkev as NULL in which case
  *         no action is performed.
*)

procedure rd_kafka_event_destroy(rkev: prd_kafka_event_t); cdecl;

(* *
  * @returns the next message from an event.
  *
  * Call repeatedly until it returns NULL.
  *
  * Event types:
  *  - RD_KAFKA_EVENT_FETCH  (1 message)
  *  - RD_KAFKA_EVENT_DR     (>=1 message(s))
  *
  * @remark The returned message(s) MUST NOT be
  *         freed with rd_kafka_message_destroy().
*)

function rd_kafka_event_message_next(rkev: prd_kafka_event_t): prd_kafka_message_t; cdecl;

(* *
  * @brief Extacts \p size message(s) from the event into the
  *        pre-allocated array \p rkmessages.
  *
  * Event types:
  *  - RD_KAFKA_EVENT_FETCH  (1 message)
  *  - RD_KAFKA_EVENT_DR     (>=1 message(s))
  *
  * @returns the number of messages extracted.
*)

function rd_kafka_event_message_array(rkev: prd_kafka_event_t; var rkmessages: prd_kafka_message_t; size: NativeUInt): NativeUInt; cdecl;

(* *
  * @returns the number of remaining messages in the event.
  *
  * Event types:
  *  - RD_KAFKA_EVENT_FETCH  (1 message)
  *  - RD_KAFKA_EVENT_DR     (>=1 message(s))
*)

function rd_kafka_event_message_count(rkev: prd_kafka_event_t): NativeUInt; cdecl;

(* *
  * @returns the error code for the event.
  *
  * Event types:
  *  - all
*)

function rd_kafka_event_error(rkev: prd_kafka_event_t): rd_kafka_resp_err_t; cdecl;

(* *
  * @returns the error string (if any).
  *          An application should check that rd_kafka_event_error() returns
  *          non-zero before calling this function.
  *
  * Event types:
  *  - all
*)

function rd_kafka_event_error_string(rkev: prd_kafka_event_t): PAnsiChar; cdecl;

(* *
  * @returns the user opaque (if any)
  *
  * Event types:
  *  - RD_KAFKA_OFFSET_COMMIT
*)

procedure rd_kafka_event_opaque(rkev: prd_kafka_event_t); cdecl;

(* *
  * @brief Extract log message from the event.
  *
  * Event types:
  *  - RD_KAFKA_EVENT_LOG
  *
  * @returns 0 on success or -1 if unsupported event type.
*)

function rd_kafka_event_log(rkev: prd_kafka_event_t; const fac, str: PAnsiCharArray; var level: integer): integer; cdecl;

(* *
  * @returns the topic partition list from the event.
  *
  * @remark The list MUST NOT be freed with rd_kafka_topic_partition_list_destroy()
  *
  * Event types:
  *  - RD_KAFKA_EVENT_REBALANCE
  *  - RD_KAFKA_EVENT_OFFSET_COMMIT
*)

function rd_kafka_event_topic_partition_list(rkev: prd_kafka_event_t): prd_kafka_topic_partition_list_t; cdecl;

(* *
  * @returns a newly allocated topic_partition container, if applicable for the event type,
  *          else NULL.
  *
  * @remark The returned pointer MUST be freed with rd_kafka_topic_partition_destroy().
  *
  * Event types:
  *   RD_KAFKA_EVENT_ERROR  (for partition level errors)
*)

function rd_kafka_event_topic_partition(rkev: prd_kafka_event_t): prd_kafka_topic_partition_t; cdecl;

(* *
  * @brief Poll a queue for an event for max \p timeout_ms.
  *
  * @returns an event, or NULL.
  *
  * @remark Use rd_kafka_event_destroy() to free the event.
*)

function rd_kafka_queue_poll(rkqu: prd_kafka_queue_t; timeout_ms: integer): prd_kafka_event_t; cdecl;

(* *@} *)

implementation

{ RD_KAFKA_OFFSET_TAIL(CNT)  (RD_KAFKA_OFFSET_TAIL_BASE - (CNT)) }
function RD_KAFKA_OFFSET_TAIL(cnt: integer): integer; inline;
begin
  result := (RD_KAFKA_OFFSET_TAIL_BASE - (cnt))
end;

function rd_kafka_message_errstr(rkmessage: prd_kafka_message_t): PAnsiChar; inline;
begin
  if ord(rkmessage.err) = 0 then
  begin
    result := nil;
    exit;
  end;
  if Assigned(rkmessage.payload) then
  begin
    result := rkmessage.payload;
    exit;

  end;
  result := rd_kafka_err2str(rkmessage.err);
end;

function rd_kafka_version; external LIBFILE;

function rd_kafka_version_str; external LIBFILE;

function rd_kafka_get_debug_contexts; external LIBFILE;

procedure rd_kafka_get_err_descs; external LIBFILE;

function rd_kafka_err2str; external LIBFILE;
function rd_kafka_err2name; external LIBFILE;

function rd_kafka_last_error; external LIBFILE;

function rd_kafka_errno2err; external LIBFILE;
function rd_kafka_errno; external LIBFILE;

procedure rd_kafka_topic_partition_destroy; external LIBFILE;

function rd_kafka_topic_partition_list_new; external LIBFILE;

procedure rd_kafka_topic_partition_list_destroy; external LIBFILE;

function rd_kafka_topic_partition_list_add; external LIBFILE;

procedure rd_kafka_topic_partition_list_add_range; external LIBFILE;

function rd_kafka_topic_partition_list_del; external LIBFILE;

function rd_kafka_topic_partition_list_del_by_idx; external LIBFILE;
function rd_kafka_topic_partition_list_copy; external LIBFILE;

function rd_kafka_topic_partition_list_set_offset; external LIBFILE;
function rd_kafka_topic_partition_list_find; external LIBFILE;

procedure rd_kafka_message_destroy; external LIBFILE;

function rd_kafka_message_timestamp; external LIBFILE;

function rd_kafka_conf_new; external LIBFILE;

procedure rd_kafka_conf_destroy; external LIBFILE;

function rd_kafka_conf_dup; external LIBFILE;

function rd_kafka_conf_set; external LIBFILE;

procedure rd_kafka_conf_set_events; external LIBFILE;

procedure rd_kafka_conf_set_dr_cb; external LIBFILE;

procedure rd_kafka_conf_set_dr_msg_cb; external LIBFILE;

procedure rd_kafka_conf_set_consume_cb; external LIBFILE;

procedure rd_kafka_conf_set_rebalance_cb; external LIBFILE;

procedure rd_kafka_conf_set_offset_commit_cb; external LIBFILE;

procedure rd_kafka_conf_set_error_cb; external LIBFILE;

procedure rd_kafka_conf_set_throttle_cb; external LIBFILE;

procedure rd_kafka_conf_set_log_cb; external LIBFILE;

procedure rd_kafka_conf_set_stats_cb; external LIBFILE;

procedure rd_kafka_conf_set_socket_cb; external LIBFILE;

{$IFNDEF MSWINDOWS}
procedure rd_kafka_conf_set_open_cb; external LIBFILE;
{$ENDIF}
procedure rd_kafka_conf_set_opaque; external LIBFILE;

procedure rd_kafka_opaque; external LIBFILE;

procedure rd_kafka_conf_set_default_topic_conf; external LIBFILE;

function rd_kafka_conf_get; external LIBFILE;

function rd_kafka_topic_conf_get; external LIBFILE;

function rd_kafka_conf_dump; external LIBFILE;

function rd_kafka_topic_conf_dump; external LIBFILE;

procedure rd_kafka_conf_dump_free; external LIBFILE;

// procedure rd_kafka_conf_properties_show; external LIBFILE;

function rd_kafka_topic_conf_new; external LIBFILE;

function rd_kafka_topic_conf_dup; external LIBFILE;

procedure rd_kafka_topic_conf_destroy; external LIBFILE;

function rd_kafka_topic_conf_set; external LIBFILE;

procedure rd_kafka_topic_conf_set_opaque; external LIBFILE;

procedure rd_kafka_topic_conf_set_partitioner_cb; external LIBFILE;

function rd_kafka_topic_partition_available; external LIBFILE;

function rd_kafka_msg_partitioner_random; external LIBFILE;
function rd_kafka_msg_partitioner_consistent; external LIBFILE;

function rd_kafka_msg_partitioner_consistent_random; external LIBFILE;

function rd_kafka_new; external LIBFILE;

procedure rd_kafka_destroy; external LIBFILE;

function rd_kafka_name; external LIBFILE;

function rd_kafka_memberid; external LIBFILE;
function rd_kafka_topic_new; external LIBFILE;

procedure rd_kafka_topic_destroy; external LIBFILE;

function rd_kafka_topic_name; external LIBFILE;

procedure rd_kafka_topic_opaque; external LIBFILE;

function rd_kafka_poll; external LIBFILE;

procedure rd_kafka_yield; external LIBFILE;
function rd_kafka_pause_partitions; external LIBFILE;

function rd_kafka_resume_partitions; external LIBFILE;

function rd_kafka_query_watermark_offsets; external LIBFILE;

function rd_kafka_get_watermark_offsets; external LIBFILE;

procedure rd_kafka_mem_free; external LIBFILE;

function rd_kafka_queue_new; external LIBFILE;

procedure rd_kafka_queue_destroy; external LIBFILE;

function rd_kafka_queue_get_main; external LIBFILE;

function rd_kafka_queue_get_consumer; external LIBFILE;
procedure rd_kafka_queue_forward; external LIBFILE;
function rd_kafka_queue_length; external LIBFILE;
procedure rd_kafka_queue_io_event_enable; external LIBFILE;
 function rd_kafka_consume_start_queue; external LIBFILE;

function rd_kafka_consume_stop; external LIBFILE;

function rd_kafka_seek; external LIBFILE;
function rd_kafka_consume; external LIBFILE;
function rd_kafka_consume_batch; external LIBFILE;
function rd_kafka_consume_callback; external LIBFILE;

function rd_kafka_consume_queue; external LIBFILE;
function rd_kafka_consume_batch_queue; external LIBFILE;

function rd_kafka_consume_callback_queue; external LIBFILE;
function rd_kafka_offset_store; external LIBFILE;

function rd_kafka_subscribe; external LIBFILE;

function rd_kafka_unsubscribe; external LIBFILE;
function rd_kafka_subscription; external LIBFILE;
function rd_kafka_consumer_poll; external LIBFILE;

function rd_kafka_consumer_close; external LIBFILE;

function rd_kafka_assign; external LIBFILE;
function rd_kafka_assignment; external LIBFILE;

function rd_kafka_commit; external LIBFILE;

function rd_kafka_commit_message; external LIBFILE;

function rd_kafka_commit_queue; external LIBFILE;

function rd_kafka_committed; external LIBFILE;

function rd_kafka_position; external LIBFILE;

Function rd_kafka_produce; external LIBFILE; // DB

function rd_kafka_produce_batch; external LIBFILE;

function rd_kafka_flush; external LIBFILE;
function rd_kafka_metadata; external LIBFILE;

procedure rd_kafka_metadata_destroy; external LIBFILE;

function rd_kafka_list_groups; external LIBFILE;

procedure rd_kafka_group_list_destroy; external LIBFILE;

function rd_kafka_brokers_add; external LIBFILE;

procedure rd_kafka_set_logger; external LIBFILE;
procedure rd_kafka_set_log_level; external LIBFILE;

procedure rd_kafka_log_print; external LIBFILE;

procedure rd_kafka_log_syslog; external LIBFILE;

function rd_kafka_outq_len; external LIBFILE;

function rd_kafka_thread_cnt; external LIBFILE;
function rd_kafka_wait_destroyed; external LIBFILE;
function rd_kafka_poll_set_consumer; external LIBFILE;
function rd_kafka_event_type; external LIBFILE;

function rd_kafka_event_name; external LIBFILE;

procedure rd_kafka_event_destroy; external LIBFILE;

function rd_kafka_event_message_next; external LIBFILE;
function rd_kafka_event_message_array; external LIBFILE;
function rd_kafka_event_message_count; external LIBFILE;

function rd_kafka_event_error; external LIBFILE;
function rd_kafka_event_error_string; external LIBFILE;

procedure rd_kafka_event_opaque; external LIBFILE;

function rd_kafka_event_log; external LIBFILE;
function rd_kafka_event_topic_partition_list; external LIBFILE;

function rd_kafka_event_topic_partition; external LIBFILE;
function rd_kafka_queue_poll; external LIBFILE;

end.
