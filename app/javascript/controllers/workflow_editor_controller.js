import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "step"]
  static values = {
    templateId: Number,
    transitions: Array
  }

  connect() {
    this.jsPlumbInstance = jsPlumb; // Use the global instance
    this.jsPlumbInstance.setContainer(this.canvasTarget);

    this.stepTargets.forEach(step => this._initializeStep(step));
    this.jsPlumbInstance.ready(() => { // Use jsPlumb.ready for initialization
      this._drawInitialConnections();
    });

    // Store handlers for unbinding
    this.beforeDropHandler = this._handleBeforeDrop.bind(this);
    this.connectionDetachedHandler = this._handleConnectionDetached.bind(this);

    this.jsPlumbInstance.bind("beforeDrop", this.beforeDropHandler);
    this.jsPlumbInstance.bind("connectionDetached", this.connectionDetachedHandler);



    // Bind the handler once and store it
    this.boundHandleSaveConnection = this.handleSaveConnection.bind(this);
    document.addEventListener("condition-form:save-connection", this.boundHandleSaveConnection);
  }

  disconnect() {
    // Remove event listener using the stored bound function
    document.removeEventListener("condition-form:save-connection", this.boundHandleSaveConnection);
    // Unbind jsPlumb events
    if (this.jsPlumbInstance) {
      this.jsPlumbInstance.unbind("beforeDrop", this.beforeDropHandler);
      this.jsPlumbInstance.unbind("connectionDetached", this.connectionDetachedHandler);
    }


    if (this.jsPlumbInstance) {
      this.jsPlumbInstance.deleteEveryEndpoint();
      this.stepTargets.forEach(step => {
        this.jsPlumbInstance.unmanage(step);
      });
    }
  }

  handleSaveConnection(event) {
    const { sourceId, targetId, condition, sourceAnchorType, targetAnchorType } = event.detail;
    this._saveConnection(sourceId, targetId, condition, sourceAnchorType, targetAnchorType);
  }

  _initializeStep = (step) => {
    // Set initial position from data attributes
    step.style.left = `${step.dataset.positionX}px`;
    step.style.top = `${step.dataset.positionY}px`;

    this.jsPlumbInstance.draggable(step, {
      containment: this.canvasTarget,
      stop: (event) => {
        // event.pos[0] is left, event.pos[1] is top
        this._savePosition(event.el.id, event.pos[0], event.pos[1]);
      }
    });

    const endpointOptions = {
      isSource: true,
      isTarget: true,
      maxConnections: -1,
      paintStyle: { fill: '#9CA3AF' },
      hoverPaintStyle: { fill: '#3B82F6' },
      connectorStyle: { stroke: '#9CA3AF', strokeWidth: 2 },
      connectorHoverStyle: { stroke: '#3B82F6', strokeWidth: 2 },
      connector: ["Flowchart", { stub: [40, 60], gap: 10, cornerRadius: 5, alwaysRespectStubs: true }],
      connectorOverlays: [
        ["Arrow", { location: 1, width: 10, length: 10 }]
      ]
    };

    this.jsPlumbInstance.addEndpoint(step, Object.assign({}, endpointOptions, { anchor: "Top" }));
    this.jsPlumbInstance.addEndpoint(step, Object.assign({}, endpointOptions, { anchor: "Right" }));
    this.jsPlumbInstance.addEndpoint(step, Object.assign({}, endpointOptions, { anchor: "Bottom" }));
    this.jsPlumbInstance.addEndpoint(step, Object.assign({}, endpointOptions, { anchor: "Left" }));
  }

  _drawInitialConnections = () => {
    this.transitionsValue.forEach(transition => {
      const sourceElement = document.getElementById(transition.source);
      const targetElement = document.getElementById(transition.target);

      if (sourceElement && targetElement) {
        const connectOptions = {
          source: sourceElement,
          target: targetElement,
          label: transition.label,
          connector: ["Flowchart", { stub: [40, 60], gap: 10, cornerRadius: 5, alwaysRespectStubs: true }],
          anchors: [transition.source_anchor_type, transition.target_anchor_type],
          overlays: [
            ["Arrow", { location: 1, width: 10, length: 10 }]
          ]
        };

        const conn = this.jsPlumbInstance.connect(connectOptions);
        conn.setParameter("transitionId", transition.id);
      } else {
        console.error(`Failed to find source or target element for transition: ${transition.source} -> ${transition.target}`);
      }
    });

    this.jsPlumbInstance.repaintEverything();
  }

  _handleBeforeDrop(info) {
    const sourceAnchorType = info.connection.endpoints[0].anchor.type;
    const targetAnchorType = info.dropEndpoint.anchor.type;
    this._openConnectionModal(info.sourceId, info.targetId, sourceAnchorType, targetAnchorType);
    return false; // Prevent jsPlumb from creating the connection immediately
  }

  _handleConnectionDetached(info, originalEvent) {
    if (originalEvent) {
      this._deleteConnection(info.connection);
    }
  }

  _openConnectionModal = (sourceId, targetId, sourceAnchorType, targetAnchorType) => {
    const organizationId = this.element.dataset.organizationId;
    const sourceStepId = sourceId.split('-')[1];
    const url = `/organizations/${organizationId}/workflow_templates/${this.templateIdValue}/workflow_steps/${sourceStepId}/condition_form?target_id=${targetId}&source_anchor_type=${sourceAnchorType}&target_anchor_type=${targetAnchorType}`;

    const modalFrame = document.getElementById('modal');
    if (modalFrame) {
      modalFrame.src = url;
    } else {
      console.error("Could not find modal turbo-frame");
    }
  }

  // ... (other methods) ...

  _saveConnection = async (sourceId, targetId, condition, sourceAnchorType, targetAnchorType) => {
    const fromId = sourceId.split("-")[1];
    const toId = targetId.split("-")[1];
    const organizationId = this.element.dataset.organizationId;
    const url = `/organizations/${organizationId}/workflow_templates/${this.templateIdValue}/workflow_transitions`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this._getCsrfToken()
        },
        body: JSON.stringify({
          workflow_transition: {
            from_id: fromId,
            to_id: toId,
            condition: condition,
            source_anchor_type: sourceAnchorType,
            target_anchor_type: targetAnchorType
          }
        })
      });

      if (response.ok) {
        const data = await response.json();

        const sourceElement = document.getElementById(sourceId);
        const targetElement = document.getElementById(targetId);

        if (sourceElement && targetElement) {
          const connectOptions = {
            source: sourceElement,
            target: targetElement,
            label: condition,
            connector: ["Flowchart", { stub: [40, 60], gap: 10, cornerRadius: 5, alwaysRespectStubs: true }],
            overlays: [
              ["Arrow", { location: 1, width: 10, length: 10 }]
            ]
          };
          // If anchor types are available, use them to specify exact anchors
          if (sourceAnchorType) {
            connectOptions.sourceAnchor = sourceAnchorType;
          }
          if (targetAnchorType) {
            connectOptions.targetAnchor = targetAnchorType;
          }

          const conn = this.jsPlumbInstance.connect(connectOptions);
          conn.setParameter("transitionId", data.transition_id);

          // Close the modal after successful save and draw
          const modalControllerElement = document.getElementById("modal").querySelector("[data-controller='modal']");
          if (modalControllerElement) {
            modalControllerElement.dispatchEvent(new Event("modal:close"));
          } else {
            console.error("Could not find modal controller element to close modal.");
          }
        } else {
          console.error(`Failed to find source or target element for programmatic connect: ${sourceId} -> ${targetId}`);
        }

        // Revert: Do not update internal state here
        // const newTransitions = this.transitionsValue;
        // newTransitions.push({
        //   id: data.transition_id,
        //   source: sourceId,
        //   target: targetId,
        //   label: condition
        // });
        // this.transitionsValue = newTransitions;

      } else {
        const errorText = await response.text();
        console.error("Failed to save connection. Server response:", errorText);
      }
    } catch (error) {
      console.error("Error during fetch operation:", error);
    }
  }
  _deleteConnection = async (connection) => {
    const transitionId = connection.getParameter("transitionId");
    if (!transitionId) return;

    const organizationId = this.element.dataset.organizationId;
    const url = `/organizations/${organizationId}/workflow_templates/${this.templateIdValue}/workflow_transitions/${transitionId}`;

    const response = await fetch(url, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this._getCsrfToken() }
    });

    if (response.ok) {
      // Revert: Do not update internal state here
      // this.transitionsValue = this.transitionsValue.filter(t => t.id !== transitionId);
    } else {
      console.error("Failed to delete connection");
      this.jsPlumbInstance.connect({
        source: connection.source,
        target: connection.target,
        label: connection.getLabel()
      }).setParameter("transitionId", transitionId);
    }
  }

  _savePosition = async (stepId, posX, posY) => {
    const stepIdNum = stepId.split("-")[1];
    const organizationId = this.element.dataset.organizationId;
    const url = `/organizations/${organizationId}/workflow_templates/${this.templateIdValue}/workflow_steps/${stepIdNum}/update_position`;

    await fetch(url, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this._getCsrfToken() },
      body: JSON.stringify({ position_x: posX, position_y: posY })
    });
  }

  _getCsrfToken = () => {
    return document.querySelector("meta[name='csrf-token']").getAttribute("content");
  }
}