#!/usr/bin/env python3
"""
Orbytring BLE Vitals Simulator
A cross-platform BLE Peripheral Simulator for Orbytring / Sensio Flutter Intern Assignment.
This script advertises a Heart Rate GATT service (0x180D) and transmits periodic 
live vital signs stream notifications mimicking a physical medical monitor.

Prerequisites:
    pip install bless

Usage:
    python ble_simulator.py
"""

import asyncio
import logging
import random
import sys
from typing import Any

# Configure logging format
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("BLE-Simulator")

try:
    from bless import (
        BlessServer,
        BlessGATTCharacteristic,
        GATTCharacteristicProperties,
        GATTAttributePermissions
    )
except ImportError:
    logger.error("The 'bless' Python library is required to run this simulator.")
    logger.error("Please run: pip install bless")
    sys.exit(1)

# Standard Heart Rate GATT UUIDs
HEART_RATE_SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb"
HEART_RATE_MEASUREMENT_UUID = "00002a37-0000-1000-8000-00805f9b34fb"

# Standard Battery GATT UUIDs
BATTERY_SERVICE_UUID = "0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID = "00002a19-0000-1000-8000-00805f9b34fb"


async def main():
    logger.info("Initializing BLE Vitals Peripheral...")

    # Instantiate server
    server = BlessServer(name="Orbytring Vitals Sim")
    
    # 1. Add Heart Rate Service
    await server.add_new_service(HEART_RATE_SERVICE_UUID)
    
    # Add Heart Rate Measurement Characteristic (Notify only)
    # Properties: Notify
    # Permissions: Read
    await server.add_new_characteristic(
        HEART_RATE_SERVICE_UUID,
        HEART_RATE_MEASUREMENT_UUID,
        GATTCharacteristicProperties.notify,
        None, # No fixed initial value
        GATTAttributePermissions.readable
    )

    # 2. Add Battery Service
    await server.add_new_service(BATTERY_SERVICE_UUID)
    
    # Add Battery Level Characteristic (Read & Notify)
    await server.add_new_characteristic(
        BATTERY_SERVICE_UUID,
        BATTERY_LEVEL_UUID,
        GATTCharacteristicProperties.read | GATTCharacteristicProperties.notify,
        bytearray([98]), # Start battery at 98%
        GATTAttributePermissions.readable
    )

    logger.info("BLE services registered successfully.")
    logger.info("Starting BLE Server advertising...")
    
    await server.start()
    logger.info("Advertising as 'Orbytring Vitals Sim'. Awaiting connections...")

    # Simulated vitals state
    heart_rate = 72.0
    battery_level = 98

    try:
        while True:
            # Check if any central is connected before logging/streaming
            # (bless automatically manages notify subscriptions, but we can write to the value to broadcast)
            
            # Simulate natural heart rate wander (BPM moves slowly with minor noise)
            heart_rate += random.uniform(-1.5, 1.5)
            heart_rate = max(60.0, min(115.0, heart_rate))
            rounded_hr = round(heart_rate)

            # Construct standard BLE Heart Rate Measurement Packet:
            # Byte 0: Flags (0x06: 8-bit format, sensor contact active)
            # Byte 1: Heart Rate Value (uint8)
            hr_payload = bytearray([0x06, rounded_hr])
            
            # Update characteristic value to trigger notify broadcasts to subscribed clients
            server.write_value(HEART_RATE_MEASUREMENT_UUID, hr_payload)
            logger.info(f"Stream telemetry update -> Heart Rate: {rounded_hr} BPM (Payload: {hr_payload.hex().upper()})")

            # Slowly decrease battery level occasionally (every ~30 seconds)
            if random.random() < 0.05:
                battery_level = max(10, battery_level - 1)
                server.write_value(BATTERY_LEVEL_UUID, bytearray([battery_level]))
                logger.info(f"Stream telemetry update -> Battery Level: {battery_level}%")

            await asyncio.sleep(1.0) # Transmit telemetry every 1 second
            
    except asyncio.CancelledError:
        logger.info("Shutting down BLE server...")
    finally:
        await server.stop()
        logger.info("BLE Server stopped.")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Simulator terminated by user.")
