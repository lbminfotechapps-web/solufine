Based on compress_video 1.0.0 from pub.dev.

Android: removed forced constant bitrate mode from TransformerEngine. Media3's default variable bitrate mode avoids requiring CBR support from device encoders. The requested bitrate, trimming, and other export settings remain intact. This addresses a suspected compatibility issue observed as encoderUnavailable / Media3 4003 on Samsung SM-A125F. Device verification is required.
