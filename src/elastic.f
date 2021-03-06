C=======================================================================
                                                                        
      SUBROUTINE ELASTIC(Z,A,E0_in,EP_in,TH_in,SIGMA)                                
                                                                        
C subroutine to calculate electron-nucleus electron scattering cross    
C section. Formulas from ASTRUC of Mo-Tsai program.                     
      IMPLICIT NONE
      REAL E0,EP,TH
      real*8 sigma
      REAL CHBAR,ALPHA,PM,PI,FDEL,FSHELL,FGAUSS
      PARAMETER (CHBAR = 19732.8)                                       
      PARAMETER (ALPHA = 7.29735E-03)                                   
      PARAMETER (PM    = 0.93828)    
      
      PARAMETER (PI    = 3.1415927)                                     
      integer in2,in,iz2
      real extra
      real*8 Z,A
      COMMON    /TARGT/ iz,iA,avgN,avgA,avgM,amuM
      Integer iz,iA
      REAL AVGN,AVGA,AVGM,AMUM
      COMMON/IKK12/IG,IDUT,INEL_MODEL,PAULI_MODEL,NUC_METHOD,NUC_MODEL
      INTEGER IG,IDUT,INEL_MODEL,PAULI_MODEL,NUC_METHOD,NUC_MODEL
      COMMON /TTYPE/ TARGET                                             
      CHARACTER*7    TARGET                                             
      REAL THR,QSQ,TAU
      REAL W1,W2,FF,CMOTT,CSMOTT,RECOIL
      REAL A_ULMAR,B_ULMAR,w2_old
      REAL*8 GE,GM,GEP,GEN,GMP,GMN
      real*8 E0_in,EP_in,TH_in
      E0 = E0_in
      EP = EP_in
      TH = TH_in
                             
      iz=Z
      iA=A
      sigma = 0.

      avgA = iA                                                         
      if (iA.le.5) then                                                 
           if (iA.eq.1)             avgM =  .93828                      
           if (iA.eq.2)             avgM = 1.87537                      
ccc pyb to try to make elastic peak work
cc           if (iA.eq.2)             avgM = 2.0
                      
           if (iA.eq.3.and.iZ.eq.1) avgM = 2.8095                       
           if (iA.eq.3.and.iZ.eq.2) avgM = 2.8094                       
           if (iA.eq.4)             avgM = 3.7284                       
      endif                                                             
                                                                        
      extra = 0.                                                        
      iN    = iA-iZ                                                     
      iN2   = iN/2*2                                                    
      iZ2   = iZ/2*2                                                    
      if (iN2.eq.iN.and.iZ2.eq.iZ) extra = -.012*(iA**(-.5))            
      if (iN2.ne.iN.and.iZ2.ne.iZ) extra =  .012*(iA**(-.5))   

                                                                        
      avgM = iN*.939573 + iZ*(.938280+.000511) - iA*.01567 +            
     +       .01723*(iA**(2./3.)) + .09315*((.5*iA-iZ)**2.)/iA +        
     +       .0006965*(iZ**2.)*(iA**(-1./3.)) + extra                   
      amuM = avgM/.931501                                               
      avgN = avgA-iZ                                                    



c removed 3/25/08
c      if(iz.lt.1) return
      

      THR = TH*PI/180.                                                  
      QSQ = 4.*E0*EP*SIN(THR/2.)**2 
      CALL NUC_FORM_FACTOR(QSQ,W1,W2,FF)                        


c THIS SKIPS REST OF CODE!!! WHY???
      IF(1.EQ.1) GO TO 1111
      TAU = QSQ/4./PM**2                                                
      CALL NFORM(IG,DBLE(QSQ),GEP,GEN,GMP,GMN)                                   
                                                                        
      IF (iA.EQ.1) THEN                                                 
           W1 = TAU*GMP**2                                              
           W2 = (GEP**2+W1)/(1.+TAU)                                    
      ELSEIF (iA.EQ.2) THEN  
        IF((IDUT.GE.11).AND.(IDUT.LE.14).AND.(QSQ.LE.3.5))THEN   !Tjon fits
           !Ulmar d2 elastic mode                                       
           CALL DEUT_U1(IDUT-10,QSQ,A_ULMAR,B_ULMAR)                     
           W1 = B_ULMAR/2.  ! sigma = sig_mot(A + B*tan...)
           W2 = A_ULMAR 
        ELSEIF(IDUT.EQ.1) THEN ! Linda Stuart's Model installed 5/30/96
           CALL FFD(DBLE(QSQ),GE,GM)   
           TAU = QSQ/4./avgM**2  
           W1 = TAU*GM**2                                              
           W2 = (GE**2+W1)/(1.+TAU) 
        ELSE   ! old  elastic deuterium from original code   
           FF  = FDEL(QSQ)                                              
           W1  = FF**2*TAU*.6667*(GMN+GMP)**2                           
           W2  = W1+(FF*(avgN*(GEN+TAU*GMN)+GEP+TAU*GMP)/(1.+TAU))**2   
        ENDIF
      ELSEIF (iA.EQ.3) THEN  !3HE  ! added 5/30/96  SER
        CALL FFHE3(DBLE(QSQ),GE,GM)
           TAU = QSQ/4./avgM**2  
           W1 = TAU*GM**2                                              
           W2 = (GE**2+W1)/(1.+TAU)  
           W2_old  = (iz*FSHELL(QSQ) )**2
      ELSEIF (iA.LE.20) THEN
           FF  = FSHELL(QSQ)                                            
           W1  = 0.                                                     
           W2  = (iZ*FF)**2                                             
      ELSE                                                              
           FF  = FGAUSS(QSQ)                                            
           W1  = 0.                                                     
           W2  = (iZ*FF)**2                                             
      ENDIF                                                             
 1111 CONTINUE

      CMOTT  = CHBAR**2*0.001*ALPHA**2/4.                               
      CSMOTT = CMOTT*COS(THR/2.)**2/(E0*SIN(THR/2.)**2)**2              
      RECOIL = avgM/(avgM+E0*(1.-COS(THR))) 
      SIGMA  = (W2+2.*W1*TAN(THR/2.)**2)*CSMOTT*RECOIL                  
!Change elastic cross section by asymetry if doing asymetry run on prot 
c     IF((                                                              
c    >    ( (   (INDEX(TARGET,'E142')+INDEX(TARGET,'E143') ).GT.0)      
c    >           .AND.(IA.EQ.1)                                         
c    >    )   .OR.                                                      
c    >    ( (INDEX(TARGET,'E149') .GT.0 ).AND.(IA.EQ.2)!fake el d2 asym 
c    >    )                                                             
c    >   )                                                              
c    >      .AND.( INDEX(TARGET,'_P').GT.0)                             
c    >   )                                                              
c    > CALL ASYM_QEL(E0,EP,THR,QSQ,TARGET,GEN,GMN,GEP,GMP,              
c    >               CSMOTT*RECOIL,SIGMA)                               
      RETURN                                                            
      END                                                               
                                                                        
C=======================================================================
!==============================================================
      SUBROUTINE NUC_FORM_FACTOR(QSQ,W1,W2,FF)
!----------------------------------------------------------------------------
! Get Nuclear Form Factor from various models
!-----------------------------------------------------------

      IMPLICIT NONE
      REAL QSQ,W1,W2,FF
      COMMON    /TARGT/ iZ,iA,avgN,avgA,avgM,amuM
                       
      INTEGER IZ,IA       
      COMMON/IKK12/IG,IDUT,INEL_MODEL,PAULI_MODEL,NUC_METHOD,NUC_MODEL
      INTEGER IG,IDUT,INEL_MODEL,PAULI_MODEL,NUC_METHOD,NUC_MODEL                                              
      REAL AVGN,AVGA,AVGM,AMUM
      REAL A_ULMAR,B_ULMAR,w2_old,PM,TAU,FDEL,FSHELL,FGAUSS,FF_BESSEL
ccc      REAL ffHe4, ffBe, ffC12, ffAl
      REAL*8 GE,GM,GEP,GEN,GMP,GMN
      LOGICAL OUT_OF_RANGE
      PARAMETER (PM    = 0.93828)  

    
      TAU = QSQ/4./PM**2   

      ig=15
c      write(*,*)ig

      CALL NFORM(IG,DBLE(QSQ),GEP,GEN,GMP,GMN)    
                                                                        
      IF (iA.EQ.1) THEN                                                 
c     fixed 3/25/08
         if(iz.eq.1) then
            W1 = TAU*GMP**2                                              
            W2 = (GEP**2+W1)/(1.+TAU)                                    
         else
            W1 = TAU*GMN**2                                              
            W2 = (GEN**2+W1)/(1.+TAU)                                    
         endif
      ELSEIF (iA.EQ.2) THEN  
         IF((IDUT.GE.11).AND.(IDUT.LE.14).AND.(QSQ.LE.3.5))THEN !Tjon fits
                                !Ulmar d2 elastic mode                                       
           CALL DEUT_U1(IDUT-10,QSQ,A_ULMAR,B_ULMAR)                     
           W1 = B_ULMAR/2.  ! sigma = sig_mot(A + B*tan...)
           W2 = A_ULMAR 
        ELSEIF(IDUT.EQ.1) THEN ! Linda Stuart's Model installed 5/30/96
           CALL FFD(DBLE(QSQ),GE,GM)   
           TAU = QSQ/4./avgM**2  
           W1 = TAU*GM**2                                              
           W2 = (GE**2+W1)/(1.+TAU) 
        ELSE   ! old  elastic deuterium from original code   
           FF  = FDEL(QSQ)                                              
           W1  = FF**2*TAU*.6667*(GMN+GMP)**2                           
           W2  = W1+(FF*(avgN*(GEN+TAU*GMN)+GEP+TAU*GMP)/(1.+TAU))**2   
        ENDIF
      ELSEIF(iA.GE.3) THEN
       W1=0.
       OUT_OF_RANGE =.FALSE.
c       IF(NUC_MODEL.EQ.1) THEN
       FF = FF_BESSEL(QSQ,OUT_OF_RANGE) !only for some Nuclei,feor limited Q2
       W2 = (iZ*FF)**2    
c       ENDIF
       IF(OUT_OF_RANGE) THEN !use if FF_BESSEL out of range
        IF (iA.EQ.3) THEN  !3HE  ! added 5/30/96  SER
           CALL FFHE3(DBLE(QSQ),GE,GM)
           TAU = QSQ/4./avgM**2  
           W1 = TAU*GM**2                                              
           W2 = (GE**2+W1)/(1.+TAU)  
           W2_old  = (iz*FSHELL(QSQ) )**2
cc these don't seem to be working right: need more testing
cc to see if actually better than ff_bessel
cc      ELSEIF (iA.EQ.4) THEN
cc         W2  = ffHe4(QSQ)
cc      ELSEIF (iA.EQ.9) THEN
cc         W2  = ffBe(QSQ)
cc      ELSEIF (iA.EQ.12) THEN
cc         W2  = ffC12(QSQ)
cc      ELSEIF (iA.EQ.27) THEN
cc         W2  = ffAl(QSQ)
        ELSEIF (iA.LE.20) THEN
           FF  = FSHELL(QSQ)
           W2  = (iZ*FF)**2 
        ELSE     !ia >20
           FF  = FGAUSS(QSQ) 
           W2  = (iZ*FF)**2                                             
        ENDIF
       ENDIF                  
      ENDIF   ! iA>+3
      RETURN
      END
!---------------------------------------------------------------------

!=========================================================================
!------------------------------------------------------------------------


                                                                        
      SUBROUTINE NFORM(IG,QQG,GEP,GEN,GMP,GMN)                             

!-----------------------------------------------------------------------
C CALCULATE NUCLEON FORM FACTORS                                        
! Modified by Steve Rock on 6/21/96 adding Peters's Phys Rev C. fit
!  and putting IG in arguements
!
C IG =1 - DIPOLE WITH FORM FACTOR SCALING AND GEN=0.0                
C     2 - IJL FIVE PARAMETER MODEL FIT                               
C     3 - GEP AND GMP FROM IJL, GMN=DIPOLE, GEN=GALSTER              
C            WE CALL THIS THE "BEST FIT" NUCLEON FORM FACTORS           
C     4 - BEST FIT EXCEPT GEN = 0.0                                  
C     5 - BLATNIK + ZOVKO VDM FIT                                    
C     6 - JANNSENS 1966 STANDARD FIT                                 
C     7 - DIPOLE + F1N = 0.0                                         
C     8 - GES = 0.0,  GMS = 1.0                                      
C     9 - GES = 1.0,  GMS = 0.0                                      
C    10 - HOHLER1 - PROTON AND NEUTRON FROM FIT 8.2                  
C    11 - HOHLER2 - PROTON FROM FIT 5.3, NEUTRON FROM 8.2            
C    12 - GARI + KRUMPELMANN, Z PHYS. A322,689(1985)                 
C    13 - KORNER + KURODA, PHYS. REV. D16,2165(1977)  
C    14 - GARI AND KRUMPELMANN WITH NE11 FIT (PETER')                  
C     15 - Peter Bosted's fit from SLAC-PUB-6651 (NE11 data + other) in
c     Phys Rev C
C    16 - Radyushkin,  Acta Physica Polonica B15 403,
c     (1984) 
c    
C QQG = INPUT Q SQUARED (GEV**2)  
!---------------------------------------------------------------------------


      IMPLICIT NONE
      INTEGER IG
      REAL*8 QQG,GEP,GEN,GMP,GMN,QQ,TAU
      REAL*8 GT,T1,T2,ALPH,TOP,BOT,RHO,F1S,F1V,F2S,F2V
      REAL*8 RS,RV,F1E,F2E,F1M,F2M
      REAL*8 F1,F2,F3,GES,GMS,GEV,GMV
      REAL*8 F1RHO,F2RHO,F1P,F2P
      REAL*8 QQP,C1,C2,C3,C4,F2VK,F2SK,F1N,F2N
      REAL*8 Q,Q3,Q4
      REAL*8 FRAC1,FRAC2,GD
      INTEGER I,IN

C IJL PARAMETERS FOR 5 PARAMETER DIPOLE FIT (IN GEV UNITS)  
C PHYS LETT. 43B, 191(1973)              
      REAL*8   GAM, BR, BW, BF, AF
      REAL*8   RMN2, RMW2, RMF2, RMR2, GAMR, PI   
      REAL*8   RMPI/ .139/,  RMPI2/ .019321  /                         
                                                                        
C PARAMETERS FOR BLATNIK AND ZOVKO VDM FIT                              
C ACTA PHYSICA AUSTRIACA 39, 62(1974)                                   
C VECTOR MESON MASSES SQUARED (GEV UNITS)  
      REAL*8     TRO, TROP, TROPP, TFI, TOM, TOMP     
                                                                        
C FITTED PARAMETERS        
      REAL*8     RMUS, RMUV, BS, BV         
                                                                        
      REAL*8     RMRHO2, CRHO, RKRHO, RKS, RMOMG2, COMG, RKOMG, RKV     
      REAL*8     RLAM12, RLAM22, RLAMQ2
                                                                        
C PARAMETERS FOR KORNER AND KURODA                                      
C VECTOR MESON MASSES SQUARED USING REGGE PARAMETER ALPHA=1.    
      REAL*8     VRH1, VRH2, VRH3, VOM1, VOM2, VOM3          
      REAL*8     RMUP/ 2.792782/ ,RMUN/ -1.913148 /                      
      common/testing/ prttst,usegrd
      logical prttst,usegrd

! Parameters for Radyuskin: From Table on p 414 of paper.               
      REAL R_QSQ(12)   / 1.,   2.,   3.,   4.,   5.,   6.,              
     >                   8.,  10.,  12.,  15.,  20.,  30./              
      REAL R_GMP_U_D(12)/ .91, 1.01, 1.05, 1.05, 1.04, 1.02,            
     >                   0.97, 0.91, 0.86, 0.78, 0.67, 0.53/            
      REAL R_GEP_D(12)  /1.00, 1.13, 1.16, 1.15, 1.11, 1.06,            
     >                   0.95, 0.86, 0.77, 0.67, 0.54, 0.38/            
      REAL R_GMN_U_D(12)/0.82, 0.80, 0.79, 0.77, 0.76, 0.74,            
     >                   0.70, 0.65, 0.61, 0.56, 0.49, 0.38/            
      REAL R_GEN_D(12)  /-.13, -.12, -.10, -.06, -.03, 0.00,            
     >                   0.05, 0.08, 0.11, 0.13, 0.14, 0.14/    
      DATA     RMN2, RMW2, RMF2, RMR2, GAMR, PI                         
     *                / 0.8817, .6146, 1.0384, 0.5852 , .112 , 3.14159/
      DATA     GAM, BR, BW, BF, AF  /0.25, 0.672, 1.102, 0.112, -0.052/
      DATA     TRO, TROP, TROPP, TFI, TOM, TOMP                         
     *                       / 0.585, 1.30,  2.10,  1.039, 0.614, 1.40 /
      DATA     RMUS, RMUV, BS, BV  / -0.060, 1.853, -0.91, -1.10 /      
      DATA     RMRHO2, CRHO, RKRHO, RKS, RMOMG2, COMG, RKOMG, RKV       
     *         /0.6022, 0.377, 6.62, -0.12, 0.6147, 0.411, 0.163, 3.706/
      DATA     RLAM12, RLAM22, RLAMQ2  /  0.632, 5.153, 0.0841 /        
      DATA       VRH1, VRH2, VRH3, VOM1, VOM2, VOM3                       
     *             / 0.593, 1.593, 2.593, 0.614, 1.614, 2.614 /
C=======================================================================
                                                                        
      QQ  = QQG/.197328**2                                              
      TAU = QQG/(4.*RMN2)                                               
      GO TO (110,120,120,120,150,160,170,180,190,200,200,               
     > 220,230,240,250,260) IG                                             
C DIPOLE                                                                
  110 GEP = 1./(1.+QQG/0.71)**2                                         
      GEN = 0.0                                                         
      GMP = RMUP*GEP                                                    
      GMN = RMUN*GEP                                                    
      RETURN                                                            
                                                                        
C IJL 5 PARAMTER JOB 
  120 GT  = 0.5/(1.+GAM*QQG)**2                                         
      T1  = SQRT(QQG+4.*RMPI2)                                          
      T2  = SQRT(QQG)                                                   
      ALPH= 2.*T1*LOG((T1+T2)/(2.*RMPI))/(T2*PI)                       
      TOP = RMR2+8.*GAMR*RMPI/PI                                        
      BOT = RMR2+QQG+(4.*RMPI2+QQG)*GAMR*ALPH/RMPI                      
      RHO = TOP/BOT                                                     
      F1S = GT*((1.-BW-BF)+BW/(1.+QQG/RMW2)+BF/(1.+QQG/RMF2))           
      F1V = GT*((1.-BR)+BR*RHO)                                         
      F2S = GT*((-0.12-AF)/(1.+QQG/RMW2)+AF/(1.+QQG/RMF2))              
      F2V = GT*(3.706*RHO)                                              
      GEP = F1V+F1S-TAU*(F2V+F2S)                                       
      GEN = F1S-F1V-TAU*(F2S-F2V)                                       
      GMP = F1V+F1S+F2V+F2S                                             
      GMN = F1S-F1V+F2S-F2V                                             
      IF (IG.EQ.2) RETURN                                               
      GD  = 1./(1.+QQG/.71)**2                                          
      GMN = RMUN*GD                                                     
      GEN = -RMUN*TAU*GD/(1.+5.6*TAU)                                   
      IF (IG.EQ.3) RETURN                                               
      GEN = 0.0                                                         
      RETURN                                                            
                                                                        
C BLATNIK AND ZOVKO                                                     
  150 RS  = 1./((1.+QQG/TOM)*(1.+QQG/TFI)*(1.+QQG/TOMP))                
      RV  = 1./((1.+QQG/TRO)*(1.+QQG/TROP)*(1.+QQG/TROPP))              
      F1E = (0.5-TAU*(RMUS+2.*RMN2*BS))*RS                              
      F2E = (0.5-TAU*(RMUV+2.*RMN2*BV))*RV                              
      F1M = (0.5+RMUS-0.5*BS*QQG)*RS                                    
      F2M = (0.5+RMUV-0.5*BV*QQG)*RV                                    
      GEP = F1E+F2E                                                     
      GMP = F1M+F2M                                                     
      GEN = F1E-F2E                                                     
      GMN = F1M-F2M                                                     
      RETURN                                                            
                                                                        
C JANNSSENS                                                             
  160 F1  = 1.+QQ/15.7                                                  
      F2  = 1.+QQ/26.7                                                  
      F3  = 1.+QQ/8.19                                                  
      GES = 0.5  *(2.5 /F1-1.6 /F2+0.10)                                
      GMS = 0.44 *(3.33/F1-2.77/F2+0.44)                                
      GEV = 0.5  *(1.16/F3-0.16)                                        
      GMV = 2.353*(1.11/F3-0.11)                                        
      GEP = GES+GEV                                                     
      GMP = GMS+GMV                                                     
      GEN = GES-GEV                                                     
      GMN = GMS-GMV                                                     
      RETURN                                                            
                                                                        
C DIPOLE + F1N = 0.0                                                    
  170 GEP = 1./(1.+QQG/0.71)**2                                         
      GEN = -RMUN*TAU*GEP                                               
      GMP =  RMUP*GEP                                                   
      GMN =  RMUN*GEP                                                   
      RETURN                                                            
                                                                        
  180 GEP = 0.0                                                         
      GEN = 0.0                                                         
      GMP = 1.0                                                         
      GMN = 0.0                                                         
      RETURN                                                            
                                                                        
  190 GEP = 1.0                                                         
      GEN = 0.0                                                         
      GMP = 0.0                                                         
      GMN = 0.0                                                         
      RETURN                                                            
                                                                        
C HOHLER1 AND HOHLER2                                                   
  200 F1RHO = 0.5*(0.955+0.090/(1.+QQG/0.355)**2)/(1.+QQG/0.536)        
      F2RHO = 0.5*(5.335+0.962/(1.+QQG/0.268))   /(1.+QQG/0.603)        
      F1S   =  0.71/(0.6129+QQG)-0.64/(1.0404+QQG)-0.13/(3.240+QQG)     
      F2S   = -0.11/(0.6129+QQG)+0.13/(1.0404+QQG)-0.02/(3.240+QQG)     
      F1V   = F1RHO+0.05/(1.464+QQG)-0.52/(6.0025+QQG)+0.28/(8.7025+QQG)
      F2V   = F2RHO-1.99/(1.464+QQG)+0.20/(6.0025+QQG)+0.19/(8.7025+QQG)
      GEP = F1V+F1S-TAU*(F2V+F2S)                                       
      GEN = F1S-F1V-TAU*(F2S-F2V)                                       
      GMP = F1V+F1S+F2V+F2S                                             
      GMN = F1S-F1V+F2S-F2V                                             
      IF (IG.EQ.10) RETURN                                              
                                                                        
C HOHLER2 - USE PROTON FIT 5.3                                          
      F1P = F1RHO+0.67/(0.6129+QQG)-0.39/(0.9216+QQG)-0.54/( 2.7556+QQG)
      F2P = F2RHO+0.04/(0.6129+QQG)-1.88/(1.2996+QQG)+0.24/(10.1761+QQG)
      GEP = F1P-TAU*F2P                                                 
      GMP = F1P+F2P                                                     
      RETURN                                                            
                                                                        
C GARI AND KRUMPELMANN                                                  
 220  QQP  = QQG*LOG(((RLAM22+QQG)/RLAMQ2))/LOG(RLAM22/RLAMQ2)          
      C1   = RLAM12/(RLAM12+QQP)                                        
      C2   = RLAM22/(RLAM22+QQP)                                        
      F1   = C1*C2                                                      
      F2   = F1*C2                                                      
      C3   = RMRHO2/(RMRHO2+QQG)                                        
      C4   = RMOMG2/(RMOMG2+QQG)                                        
      F1V  = (C3*CRHO+(1-CRHO))*F1                                      
      F1S  = (C4*COMG+(1-COMG))*F1                                      
      F2VK = (C3*CRHO*RKRHO+(RKV-CRHO*RKRHO))*F2                        
      F2SK = (C4*COMG*RKOMG+(RKS-COMG*RKOMG))*F2                        
      F1P  = 0.5*( F1S+F1V)                                             
      F1N  = 0.5*( F1S-F1V)                                             
      F2P  = 0.5*(F2SK+F2VK)                                            
      F2N  = 0.5*(F2SK-F2VK)                                            
      GEP  = F1P-TAU*F2P                                                
      GMP  = F1P+F2P                                                    
      GEN  = F1N-TAU*F2N                                                
      GMN  = F1N+F2N                                                    
      RETURN                                                            
                                                                        
C KORNER AND KURODA                                                     
  230 F1S = (1/(1+QQG/VOM1))*(1/(1+QQG/VOM2))                           
      F1V = (1/(1+QQG/VRH1))*(1/(1+QQG/VRH2))                           
      F2S = F1S*(1/(1+QQG/VOM3))                                        
      F2V = F1V*(1/(1+QQG/VRH3))                                        
      F1P = 0.5*F1S+0.5*F1V                                             
      F1N = 0.5*F1S-0.5*F1V                                             
      F2P = (RMUP-1)*(-0.0335*F2S+1.0335*F2V)                           
      F2N =    -RMUN*(-0.0335*F2S-1.0335*F2V)                           
      GEP = F1P-TAU*F2P                                                 
      GMP = F1P+F2P                                                     
      GEN = F1N-TAU*F2N                                                 
      GMN = F1N+F2N                                                     
      RETURN                                                            
                                                                        
C GARI AND KRUMPELMANN WITH NE11 FIT (PETER')                           
 240  QQP  = QQG*LOG(((RLAM22+QQG)/RLAMQ2))/LOG(RLAM22/RLAMQ2)          
      C1   = RLAM12/(RLAM12+QQP)                                        
      C2   = RLAM22/(RLAM22+QQP)                                        
      F1   = C1*C2                                                      
      F2   = F1*C2                                                      
      C3   = RMRHO2/(RMRHO2+QQG)                                        
      C4   = RMOMG2/(RMOMG2+QQG)                                        
      F1V  = (C3*CRHO+(1-CRHO))*F1                                      
      F1S  = (C4*COMG+(1-COMG))*F1                                      
      F2VK = (C3*CRHO*RKRHO+(RKV-CRHO*RKRHO))*F2                        
      F2SK = (C4*COMG*RKOMG+(RKS-COMG*RKOMG))*F2                        
      F1P  = 0.5*( F1S+F1V)                                             
      F1N  = 0.5*( F1S-F1V)                                             
      F2P  = 0.5*(F2SK+F2VK)                                            
      F2N  = 0.5*(F2SK-F2VK)                                            
      GMP  = F1P+F2P                                                    
      GEP  = GMP/RMUP                                                   
      GEN  = 0.0                                                        
      GMN  = GMP/RMUP * RMUN                                            
      RETURN                                                            

! Peter Bosted's fit from SLAC-PUB-6651 (NE11 data + other) in Phys Rev C
 250  CONTINUE
      Q = SQRT(QQG)
      Q3= Q*QQG
      Q4 = QQG*QQG
      TAU = QQG/3.52
      GEP = 1./  (1.+0.14*Q +3.01*QQG + 0.02*Q3 +1.20*Q4 +.32*Q**5)
      GMP = RMUP*GEP
      GMN = RMUN/(1.-1.74*Q +9.29*QQG - 7.63*Q3 +4.63*Q4)
      GEN = 1.25* RMUN*TAU/(1.+18.3*TAU)/((1.+QQG/.71)**2)
c     if(prttst) write(8,'(1x,11f7.3)') qqg,q,q3,q4,gep,gmp,gmn,gen
c !!! this line was missing up until 8/06!!!!
      return

 260  CONTINUE
! Radyushkin:                                                           
      GD = 1./(1.+ QQG/.71)**2                                          
      IF(QQG.LT.R_QSQ(1)) QQG=1.                                        
      IF(QQG.GT.R_QSQ(12))QQG=12.                                       
      DO I=1,11                                                         
       IF(QQG.GE.R_QSQ(I) .AND. QQG.LE.R_QSQ(I+1) ) THEN                
        IN = I                                                          
        GO TO 241                                                       
       ENDIF                                                            
      ENDDO                                                             
! Out of range.                                                         
      GMP=0.                                                            
      GMN=0.                                                            
      GEP=0.                                                            
      GEN=0.                                                            
      RETURN                                                      
! Do linear interpolation                                               
  241 FRAC1 = (QQG - R_QSQ(IN) )/(R_QSQ(IN+1) -R_QSQ(IN) )              
      FRAC2 = (R_QSQ(IN+1) -QQG)/(R_QSQ(IN+1) -R_QSQ(IN) )              
      GMP = RMUP*GD* (R_GMP_U_D(IN) * FRAC2 + R_GMP_U_D(IN+1) *FRAC1)   
      GMN = RMUN*GD* (R_GMN_U_D(IN) * FRAC2 + R_GMN_U_D(IN+1) *FRAC1)   
      GEP =      GD* (R_GEP_D  (IN) * FRAC2 + R_GEP_D  (IN+1) *FRAC1)   
      GEN =      GD* (R_GEN_D  (IN) * FRAC2 + R_GEN_D  (IN+1) *FRAC1)
      RETURN        
                                                                
      END                                                               
 !-----------------------------------------------------------------------
C-----
C       SUBROUTINE deut_elastic
C
C       AUTHOR: S. Van Verst
C       DATE:   DEC-1991
C
C       PURPOSE:
C               Calculate cross section and polarizations for deuteron
C               elastic scattering.
C
C       MODIFICATIONS:
C               Steve Rock 10/93: modified for use in Radiative
C               Correction program.  Only input arguement is QSQ.
C       DEFINITIONS:
!          IMODEL is the model number: 1= impulse approx
!                                      2= mec
!                                      3= rsc
!                                      4= rsc+mec
!            QSQ in GeV
!            A and B are from Sigma = sig_mott * [A+B*Tan2(theta/s)]
C----------------------------------------------------------------------
C
      SUBROUTINE DEUT_U1(IMODEL,QSQ,A,B)
 
      IMPLICIT NONE
      CHARACTER*6 FCFILE, FQFILE, FMFILE
      CHARACTER*20 C_FILE,Q_FILE,M_FILE
      INTEGER J, IMODEL,ILUN
 
      REAL QSQ  ! QSQ in Gev/c
      DOUBLE PRECISION QMU2,ETA,QMU2_FM
      DOUBLE PRECISION RINTERPQ
      DOUBLE PRECISION FC(100),FQ(100),FM(100),Q_2(100)
      DOUBLE PRECISION G_C,G_M,G_Q,GC2,GM2,GQ2
      REAL A,B
      DOUBLE PRECISION ALPHA,HBARC,MD
      LOGICAL FIRST /.TRUE./
      INTEGER N_D_PTS
 
      PARAMETER (MD     = 1875.630)        !Deuteron mass in MeV
      PARAMETER (ALPHA  = 7.29735E-3)      !fine structure constant
      PARAMETER (HBARC   = 197.3286)       ! MeV-Fermi
 
      if(first) then
           DO J=1,100
              FC(J)  = 0.
              FM(J)  = 0.
              FQ(J)  = 0.
              Q_2(J) = 0.
           ENDDO
C
C ------------------------------------------------------------------------
C       Ask for deuteron form factor model (from Tjon), then read them
C       in from files in DAT$D
C ------------------------------------------------------------------------
C
           WRITE(10,
     >      '('' Deut Elastic Model: ia,iamec,rsc,rscmec (1,2,3,4)='',
     >       I3)')IMODEL
           IF(IMODEL .EQ. 1)THEN
              FCFILE =  'iactjn'
              FQFILE =  'iaqtjn'
              FMFILE =  'iamtjn'
           ELSEIF(IMODEL .EQ. 2) THEN
              FCFILE =  'mecctj'
              FQFILE =  'mecqtj'
              FMFILE =  'mecmtj'
           ELSEIF(IMODEL .EQ. 3) THEN
              FCFILE =  'rscctj'
              FQFILE =  'rscqtj'
              FMFILE =  'rscmtj'
           ELSE
              FCFILE =  'rscmct'
              FQFILE =  'rscmqt'
              FMFILE =  'rscmmt'
           ENDIF
           C_FILE = FCFILE//'.tjon_input'
           Q_FILE = FQFILE//'.tjon_input'
           M_FILE = FMFILE//'.tjon_input'
           WRITE(10,'('' TJON DEUT ELASTIC FILESS TO BE OPEN='',
     >      10A,10A,10A)')    C_FILE,Q_FILE,M_FILE
           OPEN(UNIT=20,FILE=M_FILE,STATUS='OLD')
           OPEN(UNIT=21,FILE=C_FILE,STATUS='OLD')
           OPEN(UNIT=22,FILE=Q_FILE,STATUS='OLD')
C
           DO J=1,100
              READ(20,*,END=9) Q_2(J),FM(J)
              READ(21,*) Q_2(J),FC(J)
              READ(22,*) Q_2(J),FQ(J)
              N_D_PTS = J
           ENDDO
C
9          DO ILUN = 20,22
              CLOSE(UNIT=ILUN)
           ENDDO
       first=.false.
      endif
 
 
C
C----------------------------------------------------------------------
C     Calculate some kinematical quantities: UNITS ARE MEV
C----------------------------------------------------------------------
 
      QMU2 =    1.E6 *QSQ ! change from GeV**2 to MeV**2
      ETA     = QMU2/(4.D0 * MD*MD)
 
C----------------------------------------------------------------------
C     Get deuteron form factors
C----------------------------------------------------------------------
 
      QMU2_FM  = QMU2/HBARC**2   ! change to inverse fermis.
      G_C = RINTERPQ(Q_2,FC,QMU2_FM,N_D_PTS)
      G_Q = RINTERPQ(Q_2,FQ,QMU2_FM,N_D_PTS)*(MD/HBARC)**2
      G_M = RINTERPQ(Q_2,FM,QMU2_FM,N_D_PTS)
 
      GC2 = G_C**2
      GM2 = G_M**2
      GQ2 = G_Q**2
      A   = GC2 + (2.D0*ETA/3.D0) * GM2 + (8.D0*ETA*ETA/9.D0) * GQ2
      B   = (4.D0*ETA/3.D0) * (1.D0+ETA) * GM2
      RETURN
      END
C------------------------------------------------------------------------------

********************************************************************************
       SUBROUTINE FFD(Q2,GE,GM)
***************************************************************************
* This subroutine returns elastic charge and magnetic form factors for
* deuterium. 
* Errors are included for future model dependent studies.
* ***** Note that this routine is currently under construction and fits
* will all be updated in due time.
* 2/94, LMS.
* Copied from ~stuart/e143rc/code/models.f 5/30/96
***************************************************************************
       IMPLICIT NONE
       REAL*8 MD
       PARAMETER ( MD     = 1.87561339D0)    ! Deuteron mass (GeV).
!       INCLUDE 'RADCON.INC'
       LOGICAL ERROR/.FALSE./
       REAL*8 Q2, GE, GM, AQ, BQ, Q, S1, S2, S3, 
     >        BQERR, AQERR, TAU
       REAL*8 BQA/0.0046D0/, BQAERR/0.0006D0/, BQB/6.8D0/,
     >        BQBERR/0.24D0/, BQC/9.44D-09/, BQCERR/1.28D-08/,
     >        BQD/5.46D0/, BQE/1.6588D0/
       REAL*8 AQA/24.4819D0/, AQAERR/0.1913D0/, AQB/-75.0541D0/, 
     >        AQBERR/0.0425D0/, AQC/162.5866D0/, AQCERR/0.0437D0/,
     >        AQD/3.1238D0/, AQDERR/0.5446D0/, AQE/1.3093D0/,
     >        AQEERR/0.7254D0/

       AQ = 1.D0/(AQA*Q2**4 + AQB*Q2**3 + AQC*Q2**2 +
     >           AQD*Q2 + AQE)**2
       IF(ERROR) THEN
         S1 =  2.D0/(AQA*Q2**4 + AQB*Q2**3 + AQC*Q2**2 +
     >           AQD*Q2 + AQE)**3
         S2 = (AQAERR*Q2**4)**2 + (AQBERR*Q2**3)**2 +
     >        (AQCERR*Q2**2)**2 + (AQDERR*Q2)**2 +
     >         AQEERR**2
         AQERR = SQRT(S1*S1*S2)
       ENDIF

       Q = SQRT(Q2)
       BQ = BQA*EXP(-BQB*Q2) + BQC*EXP(-BQD*(Q - BQE)**2)
       IF(ERROR) THEN
         S1 = BQAERR*EXP(-BQB*Q2)
         S2 = BQA*Q2*BQBERR*EXP(-BQB*Q2)
         S3 = BQCERR*EXP(-BQD*(Q - BQE)**2)
         BQERR = SQRT(S1*S1 + S2*S2 + S3*S3)
       ENDIF
       TAU = Q2/(4.D0*MD*MD)

! Note that A(Q2) = (GC(Q2))**2 + (8/9)*TAU**2*(GQ(Q2))**2 +
! (2/3)*TAU*(1+TAU)(GM(Q2))**2 and 
! B(Q2) = (4/3)*TAU*(1+TAU)**2*(GM(Q2))**2 where
! GC is the charge form factor, GQ is the quadrupole form factor and
! GM is the magnetic form factor. Here, it is assumed that GE and GM
! follow the same functional form as given for elastic nucleon
! scattering.
       GM = SQRT(BQ/(2.D0*TAU))
       GE = SQRT( AQ*(1.D0+ TAU) - TAU*GM*GM)

       RETURN
       END

!---------------------------------------------------------------------
!---------------------------------------------------------------------

       SUBROUTINE FFHE3(Q2,GE,GM)
***************************************************************************
* This subroutine returns elastic charge and magnetic form factors for
* HE3. Low Q2 parameterization is from McCarthy, et al PRC 15, 1396 (1977).
* High Q2 parameterization for the charge form factor is from Arnold, 
* et al, PRL 40, 1429 (1978). The high Q2 parameterization is for a 
* measured combination of the charge and magnetic form factors. Here, it
* is assumed that the small magnetic form factor can be obtained from the
* low Q2 parameterization evaluated at high Q2.
* Errors are included for future model dependent studies.
*
* 2/94, LMS.
* Copied from ~stuart/e143rc/code/models.f 5/30/96
***************************************************************************
       IMPLICIT NONE
       LOGICAL ERROR/.FALSE./
       REAL*8 Q2, Q2FM, GE, GM, FC, FM, FCERR, FMERR, S1, S2,
     >        S3, S4, S5, S6, Q, TAU, MU/-3.2D0/, M/2.80833D0/, AQ2,
     >        AQ2ERR, FCHIGH, FCHIGHERR, FRAC, Z,
     >        HC2/0.0389379D0/        ! (GeV fm)**2
       REAL*8 AFC/0.675D0/, AFCERR/0.008D0/, BFC/0.366D0/, 
     >        BFCERR/0.025D0/, CFC/0.836D0/, CFCERR/0.032D0/,
     >        DFC/-0.00678D0/, DFCERR/0.00083D0/, PFC/0.9D0/,
     >        PFCERR/0.16D0/, Q0FC/3.98D0/, Q0FCERR/0.09D0/
       REAL*8 AFM/0.654D0/, AFMERR/0.024D0/, BFM/0.456D0/,
     >        BFMERR/0.029D0/, CFM/0.821D0/, CFMERR/0.053D0/
       REAL*8 AA/0.034D0/, AAERR/0.004D0/, BA/2.72D0/, BAERR/0.09D0/


       TAU = Q2/(4.D0*M*M)
       Q2FM = Q2/HC2
       Q = SQRT(Q2FM)
       IF(Q2.LT.0.8D0) THEN 
         FC = ABS(EXP(-AFC*AFC*Q2FM) - 
     >            BFC*BFC*Q2FM*EXP(-CFC*CFC*Q2FM)
     >          + DFC*EXP(-((Q - Q0FC)/PFC)**2))
         IF(ERROR) THEN
           S1 = 2.D0*AFC*Q2FM*AFCERR*EXP(-AFC*AFC*Q2FM)
           S2 = 2.D0*BFC*Q2FM*BFCERR*EXP(-CFC*CFC*Q2FM)
           S3 = 2.D0*CFC*BFC*BFC*Q2FM*Q2FM*CFCERR*EXP(-CFC*CFC*Q2FM)
           S4 = DFCERR*EXP(-((Q - Q0FC)/PFC)**2)
           S5 = 2.D0*DFC*(Q - Q0FC)/(PFC*PFC)*Q0FCERR*
     >              EXP(-((Q - Q0FC)/PFC)**2)
           S6 = S5*(Q - Q0FC)*PFCERR/(PFC*Q0FCERR)
           FCERR = SQRT(S1*S1 + S2*S2 + S3*S3 + S4*S4 + S5*S5 + S6*S6)
         ENDIF
       ENDIF

       FM = ABS(EXP(-AFM*AFM*Q2FM) - BFM*BFM*Q2FM*EXP(-CFM*CFM*Q2FM))
       IF(ERROR) THEN
         S1 = 2.D0*AFM*Q2FM*AFMERR*EXP(-AFM*AFM*Q2FM)
         S2 = 2.D0*BFM*Q2FM*BFMERR*EXP(-CFM*CFM*Q2FM)
         S3 = 2.D0*CFM*BFM*BFM*Q2FM*Q2FM*CFMERR*EXP(-CFM*CFM*Q2FM)
         FMERR = SQRT(S1*S1 + S2*S2 + S3*S3)
       ENDIF

       IF(Q2.GT.0.7D0) THEN
         AQ2 = AA*EXP(-BA*Q2)
         IF(ERROR) THEN
           S1 = AAERR*EXP(-BA*Q2)
           S2 = AQ2*Q2*BAERR
           AQ2ERR = SQRT(S1*S1 + S2*S2)
         ENDIF
         FCHIGH = SQRT(ABS(AQ2*AQ2*(1.D0 + TAU) - FM*FM*MU*MU*TAU))
         IF(ERROR) THEN
           S1 = AQ2*AQ2ERR*(1.D0 + TAU)/FCHIGH
           S2 = FM*FMERR*MU*MU*TAU/FCHIGH
           FCHIGHERR = SQRT(S1*S1 + S2*S2)
         ENDIF
         IF(Q2.GE.0.8D0) THEN
           FC = FCHIGH
           FCERR = FCHIGHERR
         ELSE                      ! Require continuity over overlap region. 
           FRAC = (Q2 - 0.7D0)/0.1D0
           FC = FRAC*FCHIGH + (1.D0 - FRAC)*FC
           IF(ERROR) THEN
             S1 = FRAC*FCHIGHERR
             S2 = (1.D0 - FRAC)*FCERR
             FCERR = SQRT(S1*S1 + S2*S2)
           ENDIF
         ENDIF
       ENDIF

! Absorb Z from Mott cross section here.
       Z = 2.D0
       GE =  Z*ABS(FC)
       GM =  Z*MU*ABS(FM)
       RETURN
       END


!---------------------------------------------------------------------

      REAL Function Fshell(T)                                                
      IMPLICIT NONE                                                                          
      common /targt/ iZ,iA,avgN,avgA,avgM,amuM                          
      INTEGER IZ,IA                                                     
      REAL AVGN,AVGA,AVGM,AMUM   
      REAL T, RADIUS,X2,ALP,CHAR
                                                                     
      Fshell = 0.                                                       
      Radius = 1.07*avgA**(1./3.)     
! from H. de Vries: Nuclear Charge Density Distributions from Elastic Electron
!   Scattering. in Atomic Data and Nuclear Data Tables 36, 495(1987)
!8/9/96
      IF(IA.EQ.16) RADIUS=2.737
      IF(IA.EQ.15) RADIUS=2.611
      IF(IA.EQ.14) RADIUS=2.540
      IF(IA.EQ.12) RADIUS=2.464  
      IF(IA.EQ. 9) RADIUS=2.519
      IF(IA.EQ. 7) RADIUS=2.39 
      IF(IA.EQ. 6) RADIUS=2.56 
      IF(IA.EQ. 4) RADIUS=1.676                                       
      x2     = (T/.197328**2)*Radius**2                                 
      alp    = (iZ-2.)/3.                                               
      char   = x2*(2.+3.*alp)/(12.+30.*alp)    
c      write(*,*)'SHELL PARAMETERS ',exp(-char),(1.-alp*x2/(6.+15.*alp))
      if (char.lt.80) Fshell = exp(-char)*(1.-alp*x2/(6.+15.*alp))      
      Return                                                            
      End                                                               
C=======================================================================
                                                                        
      REAL Function Fgauss(T)                                                
      IMPLICIT NONE                                                                             
      common /targt/ iZ,iA,avgN,avgA,avgM,amuM                          
      INTEGER IZ,IA                                                     
      REAL AVGN,AVGA,AVGM,AMUM 
      REAL T, RADIUS,X2,CHAR
                                                                        
      Fgauss = 0.                                                       
      Radius = 1.07*avgA**(1./3.)  
! from H. de Vries: Nuclear Charge Density Distributions from Elastic Electron
!   Scattering. in Atomic Data and Nuclear Data Tables 36, 495(1987)
! 8/9/96
      IF(IA.EQ.205)RADIUS=5.470
      IF(IA.EQ.56) RADIUS=3.729    
      If(IA.EQ.28) RADIUS=3.085
      IF(IA.EQ.27) RADIUS=3.035                                                        
      x2     = (T/.197328**2)*Radius**2                                 
      char   = (T/.197328**2)*(2.4**2)/6.                               
      if (char.lt.80) Fgauss = exp(-char)/(1.+x2/6.)                    
      Return                                                            
      End                                                               
C------------------------------------------------------------------------------
C     Quadratic Interpolation Routine:
C
C       Calculates Y(X0) given array Y(X) assuming a quadratic
C       dependence:  Y = AX^2 + BX + C
C
C       This routine assumes the X values are arranged in
C       ascending order but does not assume a uniform X spacing
C       of the array.
C------------------------------------------------------------------------------
C
      DOUBLE PRECISION FUNCTION RINTERPQ(X,Y,X0,NBINS)
      IMPLICIT NONE
C
      DOUBLE PRECISION X(100),Y(100),X0,DET,A,B,C
      INTEGER NBINS,I1/0/,I2/0/,I3/0/,I
C
C$$      IF(X0 .LT. X(1) .OR. X0 .GT. X(NBINS))
c$$     #    WRITE(10,'('' Extrapolating outside range: X='',G10.3)') X0
C
      IF(X0 .LE. X(1)) THEN
         I1 = 1
         I2 = 2
         I3 = 3
      ELSEIF(X0 .GE. X(NBINS-1)) THEN
         I1 = NBINS-2
         I2 = NBINS-1
         I3 = NBINS
      ELSE
         DO I=2,NBINS-1
            IF(X0 .LE. X(I)) THEN
               I1 = I-1
               I2 = I
               I3 = I+1
               GOTO 1
            ENDIF
         ENDDO
      ENDIF
C
1     DET = (X(I2)-X(I3))*(X(I1)**2 - X(I1)*(X(I2)+X(I3)) + X(I2)*X(I3))
      A = ( Y(I1)*(X(I2)-X(I3)) - X(I1)*(Y(I2)-Y(I3)) + Y(I2)*X(I3)
     #        - X(I2)*Y(I3) )/DET
      B = ( X(I1)**2*(Y(I2)-Y(I3)) - Y(I1)*(X(I2)**2-X(I3)**2)
     #        + X(I2)**2*Y(I3) - X(I3)**2*Y(I2) )/DET
      C = ( X(I1)**2*(X(I2)*Y(I3)-X(I3)*Y(I2))
     #        - X(I1)*(X(I2)**2*Y(I3)-X(I3)**2*Y(I2))
     #        + Y(I1)*(X(I2)**2*X(I3)-X(I3)**2*X(I2)) )/DET
C
      RINTERPQ = A*X0**2 + B*X0 + C
C
      RETURN
      END
C=======================================================================
                                                                        
      REAL FUNCTION FDEL(T)   
      IMPLICIT NONE       
      REAL SQF,T
                                        
      SQF  = SQRT(T/.197328**2)                                         
      FDEL = 1.58/SQF*(ATAN(SQF/0.93)-2.*ATAN(SQF/3.19)+ATAN(SQF/5.45)) 
      IF (FDEL.LE.0.) FDEL = 0.                                         
      RETURN                                                            
      END                                                               
      	REAL function FF_BESSEL ( T ,OUT_OF_RANGE)
        IMPLICIT NONE
C	Calculates PWBA form factor  for Si-28 or O-16 using 
C	Fourier-Bessel coefficients given by H. de Vries et al., 
C	Atomic Data and Nuclear Data Tables (1986).
C
C	Note: Other nuclides can be entered, but at this time this
C        is only good for 
C       He-3, C-12, N-15, O-16, Al-27, Si-28, Fe-56, Cu-65,
!----------------------------------------------------------------
!3/28/03 Corrected for divide 0/0 when qm =0  - Steve Rock
        
        REAL T
        LOGICAL OUT_OF_RANGE
	common /targt/ iZ, iA, avgN, aavgA, avgM, amuM
        real avgN, aavgA, avgM, amuM
        integer iZ, iA
	real*8 a(20),a16(14),a28(14),a3(12),a12(16),a15(8),a27(12),
     >   a56(17), a65(17),a196(15)
        INTEGER N,J,I
        REAL*8 R_MAX,QMU,Q,FF,QMUX,QM,QP,SINQR

        REAL*8 PI4/12.56637062/ ! 4*PI
        REAL*8 PI2/ 6.28318531/ ! 2*PI
C
C     de Vries, de Vries & de Jager FB coefficients:


!3He
      data a3/0.20020E-01, 0.41934E-01, 0.36254E-01, 0.17941E-01,
     1        0.46608E-02, 0.46834E-02, 0.52042E-02, 0.38280E-02,
     2        0.25661E-02, 0.14182E-02, 0.61390E-03, 0.22929E-03/
!12C
      data a12/0.15721E-01, 0.38732E-01, 0.36808E-01, 0.14671E-01,
     1        -0.43277E-02,-0.97752E-02,-0.68908E-02,-0.27631E-02,
     2        -0.63568E-03, 0.71809E-04, 0.18441E-03, 0.75066E-04,
     3         0.51069E-04, 0.14308E-04, 0.23170E-05, 0.68465E-06/


!15N7
      data a15/0.25491E-01, 0.50618E-01, 0.29822E-01, -0.55196E-02,
     1        -0.15913E-01,-0.76184E-02, -.23992E-02, -0.47940E-03/
!16 O8
      data a16/0.20238E-01, 0.44793E-01, 0.33533E-01, 0.35030E-02,
     1          -0.12293E-01,-0.10329E-01,-0.34036E-02,-0.41627E-03,
     2          -0.94435E-03,-0.25571E-03, 0.23759E-03,-0.10603E-03,
     3           0.41480E-04, 0.00000E-03/

!27Al
      data a27/0.43418E-01, 0.60298E-01,  0.28950E-02, -0.23522E-01,
     1        -0.79791E-02, 0.23010E-02,  0.10794E-02,  0.12574E-03,
     2        -0.13021E-03, 0.56563E-04, -0.18011E-04,  0.42869E-05/

!28Si
      data a28/0.33495E-01, 0.59533E-01, 0.20979E-01,-0.16900E-01,
     1          -0.14998E-01,-0.93248E-03, 0.33266E-02, 0.59244E-03,
     2          -0.40013E-03, 0.12242E-03,-0.12994E-04,-0.92784E-05,
     3           0.72595E-05,-0.42096E-05/

!56Fe26 
      data a56/ 
     1  .42018E-1,  .62337E-1,  .23995e-3, -.32776E-1, -.79941E-2,
     2  .10844E-1,  .49123e-2, -.22144e-2, -.18146E-3,  .37261E-3,
     3 -.23296E-3,  .11494E-3, -.50596E-4,  .20652E-4, -.79428E-5,
     4  .28986E-5, -.10075E-5/         

!65Cu29 
        data a65/0.45444E-01, 0.59544E-01, -.94968E-02, -.31561e-01,
     1           0.22898E-03, 0.11189E-01, 0.37360E-02, -.64873E-03,
     2	         -.51133E-03, 0.43765E-03, -.24276E-03, 0.11507E-03, 
     3           -.49761E-04, 0.20140E-04, -.76945E-05, 0.28055E-05,
     4		 -.97411E-06 /


!196Pt78
         data a196/
     1     .50218e-1,  .53722e-1, -.35015e-1, -.34588e-1,  .23564e-1,
     2     .14340e-1, -.13270e-1, -.51212e-2,  .56088e-2,  .14890e-2,
     3    -.10928e-2,  .55662e-3, -.50557e-4, -.19708e-3,  .24016e-3/  

C	Change to units of fm**(-1)
	q = sqrt ( T ) / 0.197328
	if( q .le. 0.005 ) then
            OUT_OF_RANGE=.FALSE. ! line added 4/29/98
	    FF_BESSEL = 1.00000
	    return
	endif

        FF_BESSEL=0.
        OUT_OF_RANGE=.FALSE.
        R_max=0.
	if( iA .eq. 28 ) then
            if(q.gt.2.64) OUT_OF_RANGE=.TRUE.
	    R_max = 8.
	    n = 14
	    do i = 1,n
	        a(i) = a28(i)
	    enddo
        elseif( iA .eq. 16 ) then
            if(q.gt.2.77) OUT_OF_RANGE=.TRUE.
            R_max=8.
	    n = 13
	    do  i = 1,n
	      a(i) = a16(i)
	    enddo
        elseif( iA .eq. 3 ) then
            if(q.gt.10. ) OUT_OF_RANGE=.TRUE.
            R_max=5.
	    n = 12
	    do  i = 1,n
	      a(i) = a3(i)
	    enddo
        elseif( iA .eq. 12 ) then
            if(q.gt.4.01 ) OUT_OF_RANGE=.TRUE.
            R_max=8.
	    n = 16
	    do  i = 1,n
	      a(i) = a12(i)
	    enddo
        elseif( iA .eq. 15 ) then
            if(q.gt.3.17) OUT_OF_RANGE=.TRUE.
            R_max=7
	    n = 8
	    do  i = 1,n
	      a(i) = a15(i)
	    enddo
        elseif( iA .eq. 27 ) then
            if(q.gt.2.70) OUT_OF_RANGE=.TRUE.
            R_max=7
	    n = 12
	    do  i = 1,n
	      a(i) = a27(i)
	    enddo
        elseif( iA .eq. 56 ) then
            if(q.gt.2.22) OUT_OF_RANGE=.TRUE.
            if(q.lt.0.51) OUT_OF_RANGE=.TRUE.
            R_max=9
	    n = 17
	    do  i = 1,n
	      a(i) = a56(i)
	    enddo

        elseif(( iA .eq. 64).or.(iA.eq.65) ) then
            if(q.gt.2.22) OUT_OF_RANGE=.TRUE.
            if(q.lt.0.51) OUT_OF_RANGE=.TRUE.
            R_max=9
	    n = 17
	    do  i = 1,n
	      a(i) = a65(i)
	    enddo
        elseif( iA .eq. 196)  then
            if(q.gt.2.28) OUT_OF_RANGE=.TRUE.
            if(q.lt.0.34) OUT_OF_RANGE=.TRUE.
            R_max=12
	    n = 15
	    do  i = 1,n
	      a(i) = a196(i)
	    enddo
	else      
            out_of_range=.true.
	endif
        if(out_of_range.or.r_max.eq.0.) then
          ff_bessel=0.
          Return
        endif 


	qmu = 3.14159265 / R_max

        ff=0.
        sinqR = sin(q*R_max)
        do j=1,n
	 qmux = qmu * float(j)
	 qm =  q - qmux
         qp =  q + qmux
         if(abs(qm).gt.1.e-6) then
          ff=ff+ a(j)*((-1.)**j)*sinqR/(qm*qp)
         else
          ff= ff +a(j)*R_max**2/(PI2*j)
         endif
        enddo
        if((q*R_max.gt.1.E-20).and.(ff.lt.1.E20)) then
         ff_bessel =PI4/FLOAT(IZ)/q *ff
        else
         ff_bessel=0.
        endif 
	Return
	End

                                                                       


                                                                       
