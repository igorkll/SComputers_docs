---
sidebar_position: 2
title: holoprojector
hide_title: true
sidebar-label: 'holoprojector'
---

### holoprojector api
* type - holoprojector
* reset() - resets projector settings such as scale/offset/rotation
* clear() - removes all voxels from the projector's RAM
* addVoxel(x, y, z, color, voxel_type) - adds a voxel to the projector's RAM, the voxel type is omitted 0,
the position relative to the center of the holographic projector
* flush() - renders voxels added to RAM
however it is not recommended to make more than 2048 voxels
* setOffset(x, y, z) / getOffset:x,y,z - sets the offset relative to the center of the holographic projector
* setRotation(x, y, z) / getRotation:x,y,z - sets the rotation of the entire figure relative to the center of the holographic projector
* setScale(x, y, z) / getScale:x,y,z - sets the scale
* voxel_type 0 - transparent
* voxel_type 1 - glowing
* voxel_type 2 - regular block