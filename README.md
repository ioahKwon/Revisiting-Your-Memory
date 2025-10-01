# Revisiting Your Memory: Reconstruction of Affect-Contextualized Memory via EEG-guided Audiovisual Generation (ACM MM'25 CogMAEC-W Oral)
**Official repository** for the paper "Revisiting Your Memory: Reconstruction of Affect-Contextualized Memory via EEG-guided Audiovisual Generation (RYM)". This repository provides the **RYM** demo code and the **EEG-AffectiveMemory dataset**.


<!-- - Project page: [The Official Website for RYM.](https://aesfa-nst.github.io/AesFA/) -->
- arXiv preprint: <https://arxiv.org/abs/2412.05296>
<br></br>

![Figure1](./Fig/fig1.png)

<u>Correspondence to (first authors) :</u>
- Joonwoo Kwon (kwonjoon@msu.edu)<br/>
- Sooyoung Kim (sooyoung.k@rutgers.edu) <br/>
- Heehwan Wang (dhkdgmlghks@snu.ac.kr) <br/>
- Jinwoo Lee (adem1997@snu.ac.kr)

<u>Comments</u>
- You can find the pre-trained Affect Extractor in CEBRA folder (.pt)
- For affect-text alignment, we used Claude 3.5 Sonnet with the pre-defined emotion words (details in 4.3. in the paper)
- We used Stable Diffusion ver1.5 for text encoder and LDM, while we followed MusicGEN framework and pipeline for music generation.

## Abstract
In this paper, we introduce **RevisitAffectiveMemory**, a novel task designed to reconstruct autobiographical memories through audio-visual generation guided by affect extracted from electroencephalogram (EEG) signals. To support this pioneering task, we present the **EEG-AffectiveMemory** dataset, which encompasses textual descriptions, visuals, music, and EEG recordings collected during memory recall from nine participants. Furthermore, we propose **RYM** (**R**}evisit **Y**our **M**}emory), a three-stage framework for generating synchronized audio-visual contents while maintaining dynamic personal memory affect trajectories. Experimental results demonstrate our method successfully decodes individual affect dynamics trajectories from neural signals during memory recall (F1=0.9). Also, our approach faithfully reconstructs affect-contextualized audio-visual memory across all subjects, both qualitatively and quantitatively, with participants reporting strong affective concordance between their recalled memories and the generated content. Especially, contents generated from subject-reported affect dynamics showed higher correlation with participants' reported affect dynamics trajectories (r=0.265, p<.05) and received stronger user preference (preference=56%) compared to those generated from randomly reordered affect dynamics. Our approaches advance affect decoding research and its practical applications in personalized media creation via neural-based affect comprehension.

## Methods

![Figure2](./Fig/fig2.png)

## Results
![Figure3](./Fig/fig3_revised.png)
![Figure4](./Fig/fig4_compressed.png)
![Figure5](./Fig/fig5_h.jpg)
