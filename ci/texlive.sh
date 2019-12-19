#!/usr/bin/env sh

export PATH=/tmp/texlive/bin/x86_64-linux:$PATH

# Check for cached version
if ! command -v texlua > /dev/null; then
  # Obtain TeX Live
  curl -LO http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  tar -xzf install-tl-unx.tar.gz
  cd install-tl-20*

  # Install a minimal system
  ./install-tl --profile=../texlive.profile

  cd ..
fi

# Install all the required packages
tlmgr install \
      amsfonts \
      amsmath \
      atbegshi \
      atveryend \
      bigintcalc \
      bitset \
      colortbl \
      courier \
      ctablestack \
      dvipdfmx \
      dvips \
      dvisvgm \
      ec \
      epstopdf-pkg \
      etexcmds \
      fp \
      geometry \
      gettitlestring \
      graphics \
      graphics-def \
      hycolor \
      hyperref \
      iftex \
      imakeidx \
      intcalc \
      kvdefinekeys \
      kvoptions \
      kvsetkeys \
      latex \
      latex-bin \
      letltxmacro \
      listings \
      lm \
      ltxcmds \
      luainputenc \
      luaotfload \
      luatex \
      luatexbase \
      luaxml \
      make4ht \
      makeindex \
      metafont \
      mfware \
      ms \
      oberdiek \
      pdfescape \
      pdftexcmds \
      psnfss \
      refcount \
      rerunfilecheck \
      stringenc \
      symbol \
      tex4ht \
      texlive-scripts \
      times \
      todonotes \
      tools \
      url \
      uniquecounter \
      xcolor \
      xetex \
      xkeyval \
      zapfding

# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0

# Update the TL install but add nothing new
tlmgr update --self --all --no-auto-install

# Install PGF
tlmgr init-usertree --usertree `realpath ..`
export TEXMFHOME=`realpath ..`
