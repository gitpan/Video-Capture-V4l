sub SNDCTL_DSP_GETOSPACE          (){0x8010500c}
sub SNDCTL_DSP_GETISPACE          (){0x8010500d}
sub SNDCTL_DSP_NONBLOCK           (){0x0000500e}
sub SNDCTL_DSP_GETCAPS            (){0x8004500f}
sub DSP_CAP_REVISION              (){0x000000ff}
sub DSP_CAP_DUPLEX                (){0x00000100}
sub DSP_CAP_REALTIME              (){0x00000200}
sub DSP_CAP_BATCH                 (){0x00000400}
sub DSP_CAP_COPROC                (){0x00000800}
sub DSP_CAP_TRIGGER               (){0x00001000}
sub DSP_CAP_MMAP                  (){0x00002000}
sub SNDCTL_DSP_GETTRIGGER         (){0x80045010}
sub SNDCTL_DSP_SETTRIGGER         (){0x40045010}
sub PCM_ENABLE_INPUT              (){0x00000001}
sub PCM_ENABLE_OUTPUT             (){0x00000002}
sub SNDCTL_DSP_RESET              (){0x00005000}
sub SNDCTL_DSP_SYNC               (){0x00005001}
sub SNDCTL_DSP_SPEED              (){0xc0045002}
sub SNDCTL_DSP_STEREO             (){0xc0045003}
sub SNDCTL_DSP_GETBLKSIZE         (){0xc0045004}
sub SNDCTL_DSP_SAMPLESIZE         (){0xc0045005}
sub SNDCTL_DSP_CHANNELS           (){0xc0045006}
sub SOUND_PCM_WRITE_CHANNELS      (){0xc0045006}
sub SOUND_PCM_WRITE_FILTER        (){0xc0045007}
sub SNDCTL_DSP_POST               (){0x00005008}
sub SNDCTL_DSP_SUBDIVIDE          (){0xc0045009}
sub SNDCTL_DSP_SETFRAGMENT        (){0xc004500a}
sub SNDCTL_DSP_GETFMTS            (){0x8004500b}
sub SNDCTL_DSP_SETFMT             (){0xc0045005}
sub AFMT_QUERY                    (){0x00000000}
sub AFMT_MU_LAW                   (){0x00000001}
sub AFMT_A_LAW                    (){0x00000002}
sub AFMT_IMA_ADPCM                (){0x00000004}
sub AFMT_U8                       (){0x00000008}
sub AFMT_S16_LE                   (){0x00000010}
sub AFMT_S16_BE                   (){0x00000020}
sub AFMT_S8                       (){0x00000040}
sub AFMT_U16_LE                   (){0x00000080}
sub AFMT_U16_BE                   (){0x00000100}
sub AFMT_MPEG                     (){0x00000200}
sub SNDCTL_SEQ_RESET              (){0x00005100}
sub SNDCTL_SEQ_SYNC               (){0x00005101}
sub SNDCTL_SYNTH_INFO             (){0xc08c5102}
sub SNDCTL_SEQ_CTRLRATE           (){0xc0045103}
sub SNDCTL_SEQ_GETOUTCOUNT        (){0x80045104}
sub SNDCTL_SEQ_GETINCOUNT         (){0x80045105}
sub SNDCTL_SEQ_PERCMODE           (){0x40045106}
sub SNDCTL_FM_LOAD_INSTR          (){0x40285107}
sub SNDCTL_SEQ_TESTMIDI           (){0x40045108}
sub SNDCTL_SEQ_RESETSAMPLES       (){0x40045109}
sub SNDCTL_SEQ_NRSYNTHS           (){0x8004510a}
sub SNDCTL_SEQ_NRMIDIS            (){0x8004510b}
sub SNDCTL_MIDI_INFO              (){0xc074510c}
sub SNDCTL_SEQ_THRESHOLD          (){0x4004510d}
sub SNDCTL_SYNTH_MEMAVL           (){0xc004510e}
sub SNDCTL_FM_4OP_ENABLE          (){0x4004510f}
sub SNDCTL_SEQ_PANIC              (){0x00005111}
sub SNDCTL_SEQ_OUTOFBAND          (){0x40085112}
sub SNDCTL_SEQ_GETTIME            (){0x80045113}
sub SNDCTL_SYNTH_ID               (){0xc08c5114}
sub SNDCTL_SYNTH_CONTROL          (){0xcfa45115}
sub SNDCTL_SYNTH_REMOVESAMPLE     (){0xc00c5116}

1;