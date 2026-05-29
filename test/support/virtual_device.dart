import 'dart:ui';



import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';

import 'package:tracelet/data/local/memory_message_inbox.dart';

import 'package:tracelet/domain/gateways/bottle_ocean_gateway.dart';

import 'package:tracelet/domain/models/trace_message.dart';

import 'package:tracelet/domain/models/trace_point.dart';

import 'package:tracelet/domain/models/trace_profile.dart';

import 'package:tracelet/domain/services/bottle_mail_service.dart';



/// Headless stand-in for a Tracelet handset (no GUI, no network).

class VirtualDevice {

  VirtualDevice._({

    required this.deviceId,

    required this.displayName,

    required this.bottleMail,

    required this.inbox,

  });



  final String deviceId;

  final String displayName;

  final BottleMailService bottleMail;

  final MemoryMessageInbox inbox;



  factory VirtualDevice.create({

    required String deviceId,

    required String displayName,

    required BottleOceanGateway ocean,

  }) {

    final inbox = MemoryMessageInbox();

    return VirtualDevice._(

      deviceId: deviceId,

      displayName: displayName,

      inbox: inbox,

      bottleMail: BottleMailService(

        ocean: ocean,

        inbox: inbox,

        userId: deviceId,

      ),

    );

  }



  Future<void> sendBottleMessage(

    List<TracePoint> trace, {

    TraceProfile profile = TraceProfilePresets.pureFinger,

    Size captureSize = const Size(400, 800),

  }) =>

      bottleMail.sendTrace(

        trace,

        profile: profile,

        captureSize: captureSize,

      );



  Future<TraceMessage> receiveBottleMessage() => bottleMail.receive();



  Future<List<TraceMessage>> receivedMessages() => inbox.readAll();

}



/// Two devices sharing one bottle ocean (like dev SQS FIFO).

class VirtualDevicePair {

  VirtualDevicePair._({required this.sender, required this.receiver});



  final VirtualDevice sender;

  final VirtualDevice receiver;



  factory VirtualDevicePair.create({

    String senderId = 'device-a',

    String receiverId = 'device-b',

    BottleOceanGateway? ocean,

  }) {

    final sharedOcean = ocean ?? InMemoryBottleOcean();

    return VirtualDevicePair._(

      sender: VirtualDevice.create(

        deviceId: senderId,

        displayName: 'Sender',

        ocean: sharedOcean,

      ),

      receiver: VirtualDevice.create(

        deviceId: receiverId,

        displayName: 'Receiver',

        ocean: sharedOcean,

      ),

    );

  }

}


