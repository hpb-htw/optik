private import geometry;

real rayArrowSize = 1.5mm;
real arcArrowSize = 1mm;
real mirrorThickness = 1mm;
pen mirrorColor = gray(0.85);
pen mirrorNormalLine = (dashed*0.5);
pen virtualRay = dashed;

struct NormalLine {
    point entry;
    line normalLine;

    void operator init(point entry, line normalLine){
        this.entry = entry;
        this. normalLine = normalLine;
    }
};

struct PlanaMirror {
    // conceptual properties
    /**
     * is oriented from mirror surface to outside.
     */
    vector normalDirection;
    /**
     * center point of the mirror
     */
    point center;
    /**
     * line defined by center point and normal direction.
     */
    line normalLine;
    /**
     * reflecting line of the mirror ("front side")
     */
    line surfaceLine;

    // properties for drawing:
    // private:
    private vector offsetP ;
    point mostLeft ;
    point leftOffset;
    point mostRight;
    point rightOffset;
    point normalFarthest;

    real normalLength;

    /**
     * create a PlanaMirror.
     * @param normalDirection direction of normal line
     * @param center the (default) entry point of the incomming ray
     */
    void operator init(vector normalDirection=(0, 1), point center = (0,0)) {
        this.normalDirection = normalDirection;
        this.center = center;
        this.normalLine = line(this.center, false, this.center+normalDirection);
        this.surfaceLine = perpendicular(this.center, this.normalDirection);        
    }


    /**
     * calculates the normal line by a given distance from center point of the mirror.
     * the vector in the instance of NormalLine is oriented in the direction from the
     * mirror surface to outside.
     *
     * @param incidentPosition the position of the incident point on the mirror surface.
     * That is the distance from this point to the mirror center.
     */
    NormalLine calculateNormal(real incidentPosition) {
        if(incidentPosition != 0) {
            point tmpEntry = curpoint(this.surfaceLine, incidentPosition);
            line tmpNorm = line(tmpEntry, tmpEntry + this.normalDirection);
            return NormalLine(tmpEntry, tmpNorm);
        } else {
            return NormalLine(this.center, this.normalLine);
        }
    }

    /**
     * calculate the entry point of a ray defined by source of light (point) and by a propagation direction (vector).
     * @param source source of the ray
     * @param direction propagation-direction of the ray
     * @return Normal Line at the entry point of this ray
     */
    NormalLine calculateNormal(point source, vector direction) {
        line incidentRay = line(source, source + direction);
        point entryPoint = intersectionpoint(incidentRay, this.surfaceLine);
        line tmpNormal = line(entryPoint, entryPoint + this.normalDirection);
        return NormalLine(entryPoint, tmpNormal);
    }

    /**
     * calculates the reflected point of a given source and the given normal line.
     * That is the point, which is symetrical to the source point with noral line as Ayis of Symetry.
     *
     * @param source source of line
     * @param nl normal line to the mirror surface
     *
     */
    point reflectedPoint(point source, NormalLine nl){
        line tmpNorm = nl.normalLine;
        transform tt = reflect(tmpNorm);
        return tt * source;
    }

    /**
     * calculate the reflected ray of a entry ray from given source to the (default) entry
     * point of this mirror
     */
    point reflectedPoint(point source, real incidentPosition=0) {
        NormalLine nl = calculateNormal(incidentPosition);
        return this.reflectedPoint(source, nl);
    }

    /**
     * Image point of a given source point, that is the symetrical point of the source point
     * relativity to the mirror surface
     */
    point imagePoint(point source){
        transform m = reflect(this.surfaceLine);
        return m*source;
    }


    /**
     * setup size for mirror to make it draw-able
     * @param leftWidth distance from entry point to the left side of the mirror
     * @param rightWidth distance from entry point to the right side of the mirror
     * @param normalLength the length of the drawn part of the normal ray, measured from entry point
     *
     * @return this mirror
     */
    PlanaMirror setupMirrorSize(real leftWidth, real rightWidth=leftWidth, real normalLength=leftWidth, real thickness=mirrorThickness){
        // properties for drawing:
        this.offsetP = -thickness * unit(this.normalDirection);
        this.mostLeft = curpoint(this.surfaceLine, leftWidth);
        this.leftOffset = this.mostLeft + this.offsetP;

        this.mostRight = curpoint(this.surfaceLine, -rightWidth);
        this.rightOffset = this.mostRight + this.offsetP;

        this.normalLength = normalLength;
        this.normalFarthest = this.normalLength*unit(this.normalDirection);
        return this;
    }


    /**
     * draw the mirror accorded to its side
     */
    PlanaMirror drawMirror(bool withNormal=true, pen p=defaultpen) {
        segment mSurface = segment(mostLeft, mostRight);
        fill( mostLeft -- leftOffset -- rightOffset -- mostRight -- cycle, p + mirrorColor );
        draw( mSurface );
        if(withNormal) {
            segment mNormal = segment(this.center + offsetP, this.center);//
            draw( mNormal, p);

            segment trueNormal = segment(this.center, this.center + this.normalFarthest);
            draw( trueNormal, p + mirrorNormalLine );
        }
        return this;
    }

    /**
     * @param nl must be calculate before
     */
    PlanaMirror drawNormal(NormalLine nl, real length=this.normalLength, pen p = defaultpen) {
        segment trueNormal = segment(nl.entry, nl.entry + length*unit(this.normalDirection));
        draw( trueNormal, p + mirrorNormalLine );
        return this;
    }

    /**
     * @param incidentPosition is used to calculate the normal line and the contact point on the surface of mirror
     * @param length the length of the normal segment
     */
    PlanaMirror drawNormal(real incidentPosition, real length=this.normalLength, pen p = defaultpen) {
        NormalLine nl = this.calculateNormal(incidentPosition);
        return this.drawNormal(nl, length, p);
    }


    /**
     * @param source source of ray
     * @param nl must be calculated before
     * @param arrowPosition
     */
    PlanaMirror drawIncidentRay(point source, NormalLine nl, real arrowPosition=0, pen p = defaultpen){
        line entryRay = line(source, false, nl.entry, false);
        draw(
            entryRay,
            arrow=Arrow(rayArrowSize, position=arrowPosition),
            p = p
        );
        return this;
    }

    /**
     * @param source source of ray
     * @param incidentPosition defines the position (positive or negative) from the mirror center point
     * to the entry point.
     * @param arrowPosition defines the relativ position (in Interval [0,1]) of the arrow on the
     * incident ray. The arrow is placed by value 0 at the source, by value 1 at the entry point
     * @return this mirror
     */
    PlanaMirror drawIncidentRay(point source, real incidentPosition = 0.0, real arrowPosition=0, pen p = defaultpen){
        NormalLine nl = this.calculateNormal(incidentPosition);
        return this.drawIncidentRay(source, nl, arrowPosition, p);
    }


    /**
     * @param source source of ray
     * @param nl must be calculated before
     */
    PlanaMirror drawReflectedRay(point source, NormalLine nl, real arrowPosition=1, real rayLength=0, pen p = defaultpen){
        point target = this.reflectedPoint(source, nl);
        line ray = line(nl.entry, false, target, true);
        if(rayLength > 0) {
            point target = curpoint(ray, rayLength);
            ray = line(nl.entry, false, target, false);
        }
        draw(
            ray,
            arrow=Arrow(rayArrowSize, position=arrowPosition),
            p = p
        );
        return this;
    }

    /**
     * @param source ray source
     * @param incidentPosition where the ray from source touch the mirror surface
     * @param arrowPosition
     * @param rayLength
     */
    PlanaMirror drawReflectedRay(point source, real incidentPosition = 0.0, real arrowPosition=1, real rayLength=0, pen p = defaultpen) {
        NormalLine nl = this.calculateNormal(incidentPosition);
        return this.drawReflectedRay(source, nl, arrowPosition, rayLength, p);
    }

    PlanaMirror drawImageSegment(NormalLine nl, point imagePoint, pen p = defaultpen){
        segment s = segment(nl.entry, imagePoint);
        draw( s, p + virtualRay);
        return this;
    }


    PlanaMirror labelMirror(Label surfaceL="\tLabel{Grenzfläche}", Label normalL="\tLabel{Normal}"){
        if( surfaceL.align.default) {
            label(surfaceL, this.mostLeft, align = N);
        } else {
            label(surfaceL, this.mostLeft);
        }
        if(normalL.align.default) {
            label(normalL, this.normalFarthest, align=N);
        } else {
            label(normalL, this.normalFarthest);
        }
        return this;
    }

    PlanaMirror labelRays(point source, Label incident, Label reflected=incident) {
        markangle(incident, this.normalDirection, this.center, source, arrow=Arrows(size=arcArrowSize) );
        if (reflected != null) {
            point target = this.reflectedPoint(source);
            markangle(reflected, target, this.center, this.normalDirection, arrow=Arrows(size=arcArrowSize) );
        }
        return this;
    }
}
