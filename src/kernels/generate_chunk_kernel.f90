!Crown Copyright 2014 AWE.
!
! This file is part of TeaLeaf.
!
! TeaLeaf is free software: you can redistribute it and/or modify it under
! the terms of the GNU General Public License as published by the
! Free Software Foundation, either version 3 of the License, or (at your option)
! any later version.
!
! TeaLeaf is distributed in the hope that it will be useful, but
! WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
! FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
! details.
!
! You should have received a copy of the GNU General Public License along with
! TeaLeaf. If not, see http://www.gnu.org/licenses/.

!>  @brief Fortran mesh chunk generator
!>  @author David Beckingsale, Wayne Gaudin
!>  @author Douglas Shanks (OpenACC)
!>  @details Generates the field data on a mesh chunk based on the user specified
!>  input for the states.
!>
!>  Note that state one is always used as the background state, which is then
!>  overwritten by further state definitions.

MODULE generate_chunk_kernel_module

CONTAINS

SUBROUTINE generate_chunk_kernel(x_min,x_max,y_min,y_max,halo_exchange_depth, &
                                 vertexx,                 &
                                 vertexy,                 &
                                 cellx,                   &
                                 celly,                   &
                                 density,                 &
                                 energy0,                 &
                                 u0,                      &
                                 number_of_states,        &
                                 state_density,           &
                                 state_energy,            &
                                 state_xmin,              &
                                 state_xmax,              &
                                 state_ymin,              &
                                 state_ymax,              &
                                 state_radius,            &
                                 state_geometry,          &
                                 g_rect,                  &
                                 g_circ,                  &
                                 g_point)

  IMPLICIT NONE

  INTEGER(KIND=4)      :: x_min,x_max,y_min,y_max,halo_exchange_depth
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3) :: vertexx
  REAL(KIND=8), DIMENSION(y_min-2:y_max+3) :: vertexy
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2) :: cellx
  REAL(KIND=8), DIMENSION(y_min-2:y_max+2) :: celly
  REAL(KIND=8), DIMENSION(x_min-halo_exchange_depth:x_max+halo_exchange_depth,y_min-halo_exchange_depth:y_max+halo_exchange_depth) &
                          :: density,energy0, u0
  INTEGER      :: number_of_states
  REAL(KIND=8), DIMENSION(number_of_states) :: state_density
  REAL(KIND=8), DIMENSION(number_of_states) :: state_energy
  REAL(KIND=8), DIMENSION(number_of_states) :: state_xmin
  REAL(KIND=8), DIMENSION(number_of_states) :: state_xmax
  REAL(KIND=8), DIMENSION(number_of_states) :: state_ymin
  REAL(KIND=8), DIMENSION(number_of_states) :: state_ymax
  REAL(KIND=8), DIMENSION(number_of_states) :: state_radius
  INTEGER     , DIMENSION(number_of_states) :: state_geometry
  INTEGER      :: g_rect
  INTEGER      :: g_circ
  INTEGER      :: g_point

  REAL(KIND=8) :: radius,x_cent,y_cent
  INTEGER      :: state

  INTEGER      :: j,k,jt,kt

  ! State 1 is always the background state


!$OMP PARALLEL PRIVATE(x_cent,y_cent, state,radius,jt,kt)

!$OMP DO
  DO k=y_min-halo_exchange_depth,y_max+halo_exchange_depth
    DO j=x_min-halo_exchange_depth,x_max+halo_exchange_depth
      energy0(j,k)=state_energy(1)
    ENDDO
  ENDDO
!$OMP END DO
!$OMP DO
  DO k=y_min-halo_exchange_depth,y_max+halo_exchange_depth
    DO j=x_min-halo_exchange_depth,x_max+halo_exchange_depth
      density(j,k)=state_density(1)
    ENDDO
  ENDDO
!$OMP END DO

  DO state=2,number_of_states

    x_cent=state_xmin(state)
    y_cent=state_ymin(state)

!$OMP DO
    DO k=y_min-halo_exchange_depth,y_max+halo_exchange_depth
      DO j=x_min-halo_exchange_depth,x_max+halo_exchange_depth
        IF(state_geometry(state).EQ.g_rect ) THEN
          IF (j >= x_min .and. j <= x_max .and. k >= y_min .and. k <= y_max) THEN
            IF(vertexx(j+1).GE.state_xmin(state).AND.vertexx(j).LT.state_xmax(state)) THEN
              IF(vertexy(k+1).GE.state_ymin(state).AND.vertexy(k).LT.state_ymax(state)) THEN
                energy0(j,k)=state_energy(state)
                density(j,k)=state_density(state)
              ENDIF
            ENDIF
          ENDIF
        ELSEIF(state_geometry(state).EQ.g_circ ) THEN
          radius=SQRT((cellx(j)-x_cent)*(cellx(j)-x_cent)+(celly(k)-y_cent)*(celly(k)-y_cent))
          IF(radius.LE.state_radius(state))THEN
            energy0(j,k)=state_energy(state)
            density(j,k)=state_density(state)
          ENDIF
        ELSEIF(state_geometry(state).EQ.g_point) THEN
          IF(vertexx(j).EQ.x_cent .AND. vertexy(k).EQ.y_cent) THEN
            energy0(j,k)=state_energy(state)
            density(j,k)=state_density(state)
          ENDIF
        ENDIF
      ENDDO
    ENDDO
!$OMP END DO

  ENDDO

!$OMP DO
  DO k=y_min-halo_exchange_depth, y_max+halo_exchange_depth
    DO j=x_min-halo_exchange_depth, x_max+halo_exchange_depth
      u0(j,k) = energy0(j,k)*density(j,k)
    ENDDO
  ENDDO
!$OMP END DO

!$OMP END PARALLEL

END SUBROUTINE generate_chunk_kernel

END MODULE generate_chunk_kernel_module  
