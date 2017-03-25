# Frequently asked questions

- Do you offer support for using this program? No, although you could try contacting the EEGLAB mailing list since this program is derived from the EEGLAB project https://sccn.ucsd.edu/wiki/EEGLAB_mailing_lists.

- Is there a better version of Matlab to run this program with? This program might not work with old versions of Matlab (prior to 2008b) or very recent ones. It was run with Matlab 2012b.

- Can I use this program for commercial purposes? The program itself is under the MIT license so it may be used for commercial purposes (as long it is acknowledged). The Psychophysics toolbox is also a commercial friendly license and so is LSL. However BCILAB is under GNU GPL. As long as you remove that parts of the code that uses BCILAB, you may use this program for commercial purposes.

- Can I use the program on a Windows virtual machine if there is no LSL driver for my EEG system on Mac or Linux? You probably can. While the Psychophysics toolbox time accuracy of visual feedback will not be enforced (millisecond precision), this is not a big deal when dealing with Neurofeedback protocols.

- Can I control a game in Unity3D with this program? Sure, why not? Replace the part of the code that displays the visual feedback with UDP or TCP/IP communication with Unity3D, either in Matlab or in Native Java. This should be very fast on local host.

- Can I add real-time source localization with Loreta? BCILAB supports real-time Loreta (flt_loreta.m) in beta. These features were used when generating the Glass Brain (https://www.youtube.com/watch?v=dAIQeTeMJ-I). It should be relatively easy to add Loreta to this program.
