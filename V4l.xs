#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <unistd.h>
#include <sys/mman.h>

#include <linux/videodev.h>

#define NEED_newCONSTSUB
#include "gppport.h"

#define XSRETURN_bool(bool) if (bool) XSRETURN_YES; else XSRETURN_NO;

typedef struct video_capability *Video__Capture__V4l__Capability;
typedef struct video_channel *Video__Capture__V4l__Channel;
typedef struct video_audio *Video__Capture__V4l__Audio;
typedef struct video_picture *Video__Capture__V4l__Picture;
typedef struct video_tuner *Video__Capture__V4l__Tuner;

static void
attach_struct (SV *sv, size_t bytes)
{
  void *ptr;

  sv = SvRV (sv);
  Newz (0, ptr, bytes, void*);

  sv_magic (sv, 0, '~', 0, bytes);
  mg_find(sv, '~')->mg_ptr = ptr;
}

static SV *
new_struct (SV *sv, size_t bytes, const char *pkg)
{
  SV *rv = newRV_noinc (sv);
  attach_struct (rv, bytes);
  return sv_bless (rv, gv_stashpv (pkg, TRUE));
}

static void *
old_struct (SV *sv, const char *name)
{
  /* TODO: check name */
  return mg_find (SvRV(sv), '~')->mg_ptr;
}

static int
framesize (unsigned int format, unsigned int pixels)
{
  if (format==VIDEO_PALETTE_RGB565)	return pixels*2;
  if (format==VIDEO_PALETTE_RGB24)	return pixels*3;
  if (format==VIDEO_PALETTE_RGB555)	return pixels*2;
  if (format==VIDEO_PALETTE_HI240)	return pixels*1;
  if (format==VIDEO_PALETTE_GREY)	return pixels*1;
  if (format==VIDEO_PALETTE_RGB32)	return pixels*4;
  if (format==VIDEO_PALETTE_UYVY)	return pixels*2;
  if (format==VIDEO_PALETTE_YUYV)	return pixels*2;
  /* everything below is very probably WRONG */
  if (format==VIDEO_PALETTE_PLANAR)	return pixels*0;
  if (format==VIDEO_PALETTE_RAW)	return pixels*0;
  if (format==VIDEO_PALETTE_YUV410P)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV411)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV411P)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV420)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV420P)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV422)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV422P)	return pixels*3/2;
  return 0;
}

struct private {
  int fd;
  unsigned char *mmap_base;
  struct video_mbuf vm;
};

static int
private_free (SV *obj, MAGIC *mg)
{
  struct private *p = (struct private *)mg->mg_ptr;
  munmap (p->mmap_base, p->vm.size);
  return 0;
}

static MGVTBL vtbl_private = {0, 0, 0, 0, private_free};

static struct private *
find_private (SV *sv)
{
  HV *hv = (HV*)SvRV(sv);
  MAGIC *mg = mg_find ((SV*)hv, '~');

  if (!mg)
    {
      struct private p;
      p.fd = SvIV (*hv_fetch (hv, "fd", 2, 0));
      if (ioctl (p.fd, VIDIOCGMBUF, &p.vm) == 0)
        {
          p.mmap_base = (unsigned char *)mmap (0, p.vm.size, PROT_READ|PROT_WRITE, MAP_SHARED, p.fd, 0);
          if (p.mmap_base)
            {
              sv_magic ((SV*)hv, 0, '~', (char*)&p, sizeof p);
              mg = mg_find ((SV*)hv, '~');
              mg->mg_virtual = &vtbl_private;
            }
        }
    }

  return (struct private *) (mg ? mg->mg_ptr : 0);
}

typedef unsigned char u8;
typedef unsigned int UI;

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l		

PROTOTYPES: ENABLE

SV *
reduce(in,w,m)
	SV *	in
        UI w
        UI m
        CODE:
{
        UI sz = SvCUR (in) / (m*m);
        UI y;
        SV *rs = newSVpv ("", 0);
        u8 *src, *dst, *end;

        SvGROW (rs, sz);
        SvCUR_set (rs, sz);
        src = SvPV_nolen (in);
        dst = SvPV_nolen (rs);

        if (m != 8)
           croak ("m must be 8");

        for (y = sz / (m*3); --y; )
          {
            end = src + w * 3;
            do
              {
                dst[0] = ((UI)src[ 0] + (UI)src[ 3] + (UI)src[ 6] + (UI)src[ 9] +
                          (UI)src[12] + (UI)src[15] + (UI)src[18] + (UI)src[21] + 3) >> 3;
                dst[1] = ((UI)src[ 1] + (UI)src[ 4] + (UI)src[ 7] + (UI)src[10] +
                          (UI)src[13] + (UI)src[16] + (UI)src[19] + (UI)src[22] + 3) >> 3;
                dst[2] = ((UI)src[ 2] + (UI)src[ 5] + (UI)src[ 8] + (UI)src[11] +
                          (UI)src[14] + (UI)src[17] + (UI)src[20] + (UI)src[23] + 3) >> 3;
                dst += 3;
                src += 24;
              }
            while (src < end);
            src += w*(m-1)*3;
          }

        RETVAL=rs;
}
	OUTPUT:
        RETVAL

SV *
normalize(in)
	SV *	in
        CODE:
{
        UI sz = SvCUR (in);
        u8 min = 255, max = 0;
        SV *rs = newSVpv ("", 0);
        u8 *src, *dst, *end;

        SvGROW (rs, sz);
        SvCUR_set (rs, sz);
        end = SvEND (in);
        dst = SvPV_nolen (rs);

        for (src = SvPV_nolen (in); src < end; src++)
          {
            if (*src > max) max = *src;
            if (*src < min) min = *src;
          }

        if (max != min)
          for (src = SvPV_nolen (in); src < end; )
              *dst++ = ((UI)*src++ - min) * 255 / (max-min);
        else
          for (src = SvPV_nolen (in); src < end; )
              *dst++ = *src++;

        RETVAL=rs;
}
	OUTPUT:
        RETVAL

void
findmin(db,fr)
	SV *db
        SV *fr
        PPCODE:
{
	UI diff, min = -1;
        UI minindex, index = 0;
        u8 *src, *dst, *end;

        src = SvPV_nolen (db);
        end = SvEND (db);

        do
          {
            dst = SvPV_nolen (fr);
            end = src + SvCUR (fr);
            diff = 0;

            do
              diff += abs ((int)*src++ - (int)*dst++);
            while (src < end);

            if (min > diff)
              {
                min = diff;
                minindex = index;
              }

            index++;
          }
        while (src < (u8*)SvEND (db));

        EXTEND (sp, 2);
        PUSHs (sv_2mortal (newSViv (minindex)));
        PUSHs (sv_2mortal (newSViv ((min << 8) / SvCUR (fr))));
}

SV *
capture(sv,frame,width,height,format = VIDEO_PALETTE_RGB24)
	SV	*sv
        unsigned int	frame
        unsigned int	width
        unsigned int	height
        unsigned int	format
        CODE:
{
        struct private *p;
        if ((p = find_private (sv)))
          {
            struct video_mmap vm;
            vm.frame  = frame;
            vm.height = height;
            vm.width  = width;
            vm.format = format;
            if (ioctl (p->fd, VIDIOCMCAPTURE, &vm) == 0)
              {
                SV *fr = newSV (0);
                SvUPGRADE (fr, SVt_PV);
                SvREADONLY_on (fr);
                SvPVX (fr) = p->mmap_base + p->vm.offsets[frame];
                SvCUR_set (fr, framesize (format, width*height));
                SvLEN_set (fr, 0);
                SvPOK_only (fr);
                RETVAL = fr;
              }
            else
              XSRETURN_EMPTY;
          }
        else
          XSRETURN_EMPTY;
}
        OUTPUT:
        RETVAL

void
sync(sv,frame)
	SV	*sv
        int	frame
        PPCODE:
{
        struct private *p;
        if ((p = find_private (sv))
            && ioctl (p->fd, VIDIOCSYNC, &frame) == 0)
          XSRETURN_YES;
        else
          XSRETURN_EMPTY;
}

unsigned long
_freq (fd,fr)
  	int fd
        unsigned long fr
        CODE:
        if (items > 1)
          {
            fr = (fr+499)*16/1000;
            ioctl (fd, VIDIOCSFREQ, &fr);
          }
        if (GIMME_V != G_VOID)
          {
            if (ioctl (fd, VIDIOCGFREQ, &fr) == 0)
              RETVAL = fr*1000/16;
            else
              XSRETURN_EMPTY;
          }
        else
          XSRETURN (0);
        OUTPUT:
        RETVAL


SV *
_capabilities_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_capability), "Video::Capture::V4l::Capability");
        OUTPUT:
        RETVAL

SV *
_channel_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_channel), "Video::Capture::V4l::Channel");
        OUTPUT:
        RETVAL

SV *
_tuner_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_tuner), "Video::Capture::V4l::Tuner");
        OUTPUT:
        RETVAL

SV *
_audio_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_audio), "Video::Capture::V4l::Audio");
        OUTPUT:
        RETVAL

SV *
_picture_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_picture), "Video::Capture::V4l::Picture");
        OUTPUT:
        RETVAL

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Capability

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGCAP, old_struct (sv, "Video::Capture::V4l::Capability")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Channel

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGCHAN, old_struct (sv, "Video::Capture::V4l::Channel")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSCHAN, old_struct (sv, "Video::Capture::V4l::Channel")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Tuner

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGTUNER, old_struct (sv, "Video::Capture::V4l::Tuner")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSTUNER, old_struct (sv, "Video::Capture::V4l::Tuner")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Audio

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGAUDIO, old_struct (sv, "Video::Capture::V4l::Audio")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSAUDIO, old_struct (sv, "Video::Capture::V4l::Audio")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Picture

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGPICT, old_struct (sv, "Video::Capture::V4l::Picture")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSPICT, old_struct (sv, "Video::Capture::V4l::Picture")) == 0);

# accessors/mutators
INCLUDE: genacc |

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l		

BOOT:
{
	HV *stash = gv_stashpvn("Video::Capture::V4l", 19, TRUE);

	newCONSTSUB(stash,"AUDIO_BASS",	newSViv(VIDEO_AUDIO_BASS));
	newCONSTSUB(stash,"AUDIO_MUTABLE",	newSViv(VIDEO_AUDIO_MUTABLE));
	newCONSTSUB(stash,"AUDIO_MUTE",	newSViv(VIDEO_AUDIO_MUTE));
	newCONSTSUB(stash,"AUDIO_TREBLE",	newSViv(VIDEO_AUDIO_TREBLE));
	newCONSTSUB(stash,"AUDIO_VOLUME",	newSViv(VIDEO_AUDIO_VOLUME));
	newCONSTSUB(stash,"CAPTURE_EVEN",	newSViv(VIDEO_CAPTURE_EVEN));
	newCONSTSUB(stash,"CAPTURE_ODD",	newSViv(VIDEO_CAPTURE_ODD));
	newCONSTSUB(stash,"MAX_FRAME",	newSViv(VIDEO_MAX_FRAME));
	newCONSTSUB(stash,"MODE_AUTO",	newSViv(VIDEO_MODE_AUTO));
	newCONSTSUB(stash,"MODE_NTSC",	newSViv(VIDEO_MODE_NTSC));
	newCONSTSUB(stash,"MODE_PAL",	newSViv(VIDEO_MODE_PAL));
	newCONSTSUB(stash,"MODE_SECAM",	newSViv(VIDEO_MODE_SECAM));
	newCONSTSUB(stash,"PALETTE_COMPONENT",	newSViv(VIDEO_PALETTE_COMPONENT));
	newCONSTSUB(stash,"PALETTE_GREY",	newSViv(VIDEO_PALETTE_GREY));
	newCONSTSUB(stash,"PALETTE_HI240",	newSViv(VIDEO_PALETTE_HI240));
	newCONSTSUB(stash,"PALETTE_PLANAR",	newSViv(VIDEO_PALETTE_PLANAR));
	newCONSTSUB(stash,"PALETTE_RAW",	newSViv(VIDEO_PALETTE_RAW));
	newCONSTSUB(stash,"PALETTE_RGB24",	newSViv(VIDEO_PALETTE_RGB24));
	newCONSTSUB(stash,"PALETTE_RGB32",	newSViv(VIDEO_PALETTE_RGB32));
	newCONSTSUB(stash,"PALETTE_RGB555",	newSViv(VIDEO_PALETTE_RGB555));
	newCONSTSUB(stash,"PALETTE_RGB565",	newSViv(VIDEO_PALETTE_RGB565));
	newCONSTSUB(stash,"PALETTE_UYVY",	newSViv(VIDEO_PALETTE_UYVY));
	newCONSTSUB(stash,"PALETTE_YUV410P",	newSViv(VIDEO_PALETTE_YUV410P));
	newCONSTSUB(stash,"PALETTE_YUV411",	newSViv(VIDEO_PALETTE_YUV411));
	newCONSTSUB(stash,"PALETTE_YUV411P",	newSViv(VIDEO_PALETTE_YUV411P));
	newCONSTSUB(stash,"PALETTE_YUV420",	newSViv(VIDEO_PALETTE_YUV420));
	newCONSTSUB(stash,"PALETTE_YUV420P",	newSViv(VIDEO_PALETTE_YUV420P));
	newCONSTSUB(stash,"PALETTE_YUV422",	newSViv(VIDEO_PALETTE_YUV422));
	newCONSTSUB(stash,"PALETTE_YUV422P",	newSViv(VIDEO_PALETTE_YUV422P));
	newCONSTSUB(stash,"PALETTE_YUYV",	newSViv(VIDEO_PALETTE_YUYV));
	newCONSTSUB(stash,"SOUND_LANG1",	newSViv(VIDEO_SOUND_LANG1));
	newCONSTSUB(stash,"SOUND_LANG2",	newSViv(VIDEO_SOUND_LANG2));
	newCONSTSUB(stash,"SOUND_MONO",	newSViv(VIDEO_SOUND_MONO));
	newCONSTSUB(stash,"SOUND_STEREO",	newSViv(VIDEO_SOUND_STEREO));
	newCONSTSUB(stash,"TUNER_LOW",	newSViv(VIDEO_TUNER_LOW));
	newCONSTSUB(stash,"TUNER_MBS_ON",	newSViv(VIDEO_TUNER_MBS_ON));
	newCONSTSUB(stash,"TUNER_NORM",	newSViv(VIDEO_TUNER_NORM));
	newCONSTSUB(stash,"TUNER_NTSC",	newSViv(VIDEO_TUNER_NTSC));
	newCONSTSUB(stash,"TUNER_PAL",	newSViv(VIDEO_TUNER_PAL));
	newCONSTSUB(stash,"TUNER_RDS_ON",	newSViv(VIDEO_TUNER_RDS_ON));
	newCONSTSUB(stash,"TUNER_SECAM",	newSViv(VIDEO_TUNER_SECAM));
	newCONSTSUB(stash,"TUNER_STEREO_ON",	newSViv(VIDEO_TUNER_STEREO_ON));
	newCONSTSUB(stash,"TYPE_CAMERA",	newSViv(VIDEO_TYPE_CAMERA));
	newCONSTSUB(stash,"TYPE_TV",	newSViv(VIDEO_TYPE_TV));
	newCONSTSUB(stash,"VC_AUDIO",	newSViv(VIDEO_VC_AUDIO));
	newCONSTSUB(stash,"VC_TUNER",	newSViv(VIDEO_VC_TUNER));
	newCONSTSUB(stash,"TYPE_CAPTURE",	newSViv(VID_TYPE_CAPTURE));
	newCONSTSUB(stash,"TYPE_CHROMAKEY",	newSViv(VID_TYPE_CHROMAKEY));
	newCONSTSUB(stash,"TYPE_CLIPPING",	newSViv(VID_TYPE_CLIPPING));
	newCONSTSUB(stash,"TYPE_FRAMERAM",	newSViv(VID_TYPE_FRAMERAM));
	newCONSTSUB(stash,"TYPE_MONOCHROME",	newSViv(VID_TYPE_MONOCHROME));
	newCONSTSUB(stash,"TYPE_OVERLAY",	newSViv(VID_TYPE_OVERLAY));
	newCONSTSUB(stash,"TYPE_SCALES",	newSViv(VID_TYPE_SCALES));
	newCONSTSUB(stash,"TYPE_SUBCAPTURE",	newSViv(VID_TYPE_SUBCAPTURE));
	newCONSTSUB(stash,"TYPE_TELETEXT",	newSViv(VID_TYPE_TELETEXT));
	newCONSTSUB(stash,"TYPE_TUNER",	newSViv(VID_TYPE_TUNER));
}

